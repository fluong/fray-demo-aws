# fray-demo-aws

Live demo of [Fray](https://github.com/fluong/fray): a sample AWS stack whose
pull requests get STRIDE threat-model comments and a merge gate.

Plans run against LocalStack **STS only** — no real AWS credentials, and
nothing is applied. The Fray Action authenticates to the hosted API with
GitHub Actions OIDC (`aud` = `fray`).

## Layout

| Path | Purpose |
|------|---------|
| `infra/` | `aws-web-app` fixture from `fluong/fray` (plan-only; see `infra/NOTICE`) |
| `infra/ci.tf` | LocalStack STS endpoint + dummy AWS keys for CI |
| `fray.yaml` | Empty augmentation (`schema_version: fray-config/v1`) |
| `.fray/waivers.yml` | Example accepted-risk waiver (see [Waivers](#waivers)) |
| `.github/CODEOWNERS` | Requires `@fluong` review for changes under `.fray/` |
| `.github/workflows/fray.yml` | `fluong/fray@v0.7.0` against the hosted API |

## How CI works

On `pull_request` and `push` to `main`:

1. Starts LocalStack with `SERVICES=sts` only
2. Checks out the repo (`fetch-depth: 0` for base-commit compares)
3. Runs `fluong/fray@v0.7.0` with `working-directory: infra`
4. Fray runs `terraform init` / `plan` / `show -json`, POSTs the DFD over OIDC,
   updates the PR comment, uploads SARIF, and fails the job when the gate blocks

Permissions required: `id-token: write`, `contents: read`, `pull-requests: write`,
`security-events: write`.

The Action `api-url` is `https://api.getfray.dev` (push, pull_request, and
`workflow_dispatch` share the same job). Fork PRs cannot mint an
OIDC token for audience `fray` — Fray skips with a warning (never a silent pass).

## Demo pull requests

| PR | Change | Gate |
|---|---|---|
| [#1](https://github.com/fluong/fray-demo-aws/pull/1) | Extra `GetSecretValue` on `Resource "*"` → **FR-007** | Not blocking (merge allowed) |
| [#2](https://github.com/fluong/fray-demo-aws/pull/2) | S3 Block Public Access flags cleared → **FR-025** | Blocked (merge refused) |

Open findings planted in the baseline fixture (see comments in `infra/main.tf`)
include FR-001, FR-003, FR-005, FR-009, FR-012, FR-014, and FR-026. The demo PRs
add *new* findings relative to that baseline to exercise advisory vs blocking.

## Waivers

Accepted risks live in **`.fray/waivers.yml`** (Fray Action v0.7.0+). This repo
waives the planted **FR-009** (low) finding on the database password secret —
rotation is left off on purpose in the fixture, and the waiver documents that
choice with an expiry.

```yaml
# .fray/waivers.yml (excerpt)
version: 1
waivers:
  - id: demo-db-secret-rotation
    rule: FR-009
    address: module.db_password.aws_secretsmanager_secret.this[0]
    reason: "Demo fixture: rotation is intentionally off so FR-009 stays visible until waived."
    owner: "@fluong"
    expires: "2026-12-08"
```

Reason and owner stay in git; Fray only receives the waiver id, rule, hashed
target id, and expiry. See the [Fray README — Waivers](https://github.com/fluong/fray#waivers).

**CODEOWNERS:** `/.fray/ @fluong` so changes to the waiver file need review
before merge. Fray does not enforce GitHub review rules — CODEOWNERS is the
repo’s protection.

`mitigations.yaml` is removed (empty legacy file; superseded by `.fray/waivers.yml`).

## Config

```yaml
# fray.yaml
schema_version: fray-config/v1
```

No declared elements — the scan is pure plan inference plus Fray’s server-side
rules, plus the example waiver above.

## Related

- [fluong/fray](https://github.com/fluong/fray) — public client and Action
- Hosted API / rules — private companion (`fray-server`)

## License

Apache-2.0 for original files. Third-party Terraform module attributions are in
`infra/NOTICE`.
