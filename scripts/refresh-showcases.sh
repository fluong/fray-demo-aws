#!/usr/bin/env bash
# Rebase every origin/demo/* branch onto origin/main and force-push when the
# tip moved. Each showcase branch must be exactly one scenario commit over
# main, and that commit must not touch .github/.
#
# Usage: scripts/refresh-showcases.sh [--dry-run]
set -euo pipefail

dry_run=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    -h|--help)
      echo "Usage: $0 [--dry-run]" >&2
      exit 0
      ;;
    *)
      echo "unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

ensure_identity() {
  if [[ -z "$(git config --get user.email 2>/dev/null || true)" ]]; then
    git config user.email "github-actions[bot]@users.noreply.github.com"
  fi
  if [[ -z "$(git config --get user.name 2>/dev/null || true)" ]]; then
    git config user.name "github-actions[bot]"
  fi
}

die() {
  echo "error: $*" >&2
  exit 1
}

ensure_identity

if [[ -n "$(git status --porcelain)" ]]; then
  die "working tree not clean; commit or stash before refreshing showcases"
fi

git fetch origin --prune

branches=()
while IFS= read -r b; do
  [[ -z "$b" ]] && continue
  branches+=("$b")
done < <(git for-each-ref --format='%(refname:lstrip=3)' refs/remotes/origin/demo/ | sort)
if [[ ${#branches[@]} -eq 0 ]]; then
  die "no origin/demo/* branches found"
fi

# --- Phase 1: pre-check every branch before any rebase or push -------------
for b in "${branches[@]}"; do
  remote="origin/${b}"
  if ! git rev-parse --verify -q "$remote" >/dev/null; then
    die "${b}: missing remote ref ${remote}"
  fi

  count="$(git rev-list --count "origin/main..${remote}")"
  if [[ "$count" -ne 1 ]]; then
    die "${b}: expected exactly 1 commit over origin/main, found ${count}"
  fi
  tip="$(git rev-parse "${remote}")"
  files="$(git diff-tree --no-commit-id --name-only -r "$tip")"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
      .github|.github/*)
        die "${b}: scenario commit touches ${f} (must not touch .github/)"
        ;;
    esac
  done <<<"$files"
done

# --- Phase 2: rebase every branch; abort all-or-nothing on conflict --------
# Push only in phase 3 so a mid-loop rebase failure never leaves later
# branches unpushed while earlier ones already moved on the remote.
for b in "${branches[@]}"; do
  remote="origin/${b}"
  git switch -C "$b" "$remote"
  if ! git rebase origin/main; then
    if [[ -d "$(git rev-parse --git-path rebase-merge)" ]] || [[ -d "$(git rev-parse --git-path rebase-apply)" ]]; then
      git rebase --abort
    fi
    die "${b}: rebase onto origin/main failed; aborted"
  fi

  count="$(git rev-list --count "origin/main..HEAD")"
  if [[ "$count" -ne 1 ]]; then
    die "${b}: after rebase expected exactly 1 commit over origin/main, found ${count}"
  fi
  if ! git diff --quiet origin/main -- .github/workflows; then
    die "${b}: .github/workflows/ differs from origin/main after rebase"
  fi
done

# --- Phase 3: push (or report) ---------------------------------------------
for b in "${branches[@]}"; do
  git switch --quiet "$b"
  remote="origin/${b}"
  if [[ "$(git rev-parse HEAD)" == "$(git rev-parse "$remote")" ]]; then
    echo "up to date: ${b}"
    continue
  fi
  if [[ "$dry_run" -eq 1 ]]; then
    echo "would refresh: ${b} ($(git rev-parse --short HEAD))"
    continue
  fi
  git push --force-with-lease="${b}:${remote}" origin "$b"
  echo "refreshed: ${b}"
done

git switch --quiet main
