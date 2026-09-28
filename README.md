# fray-demo-aws

Live demo of [Fray](https://github.com/fluong/fray): a sample AWS stack whose
pull requests get STRIDE threat-model comments and a merge gate. Plans run
against LocalStack **STS only** — no cloud credentials.

## What this repo contains

- `infra/` — the `aws-web-app` fixture from `fluong/fray` (see `infra/NOTICE`)
- `fray.yaml` / `mitigations.yaml` — empty augmentation and dispositions
- `.github/workflows/fray.yml` — `fluong/fray@v0.2.0` against the hosted API

## Demo pull requests

| PR | Change | Gate |
|---|---|---|
| Advisory | `task_exec_secret_arns` widened to `"*"` → **FR-007** | Not blocking (merge allowed) |
| Blocking | S3 public-access block flags cleared → **FR-010** | Blocked (merge refused) |

Links are filled in after the baseline push and PRs are opened.

## License

Apache-2.0 for original files. Third-party Terraform module attributions are in
`infra/NOTICE`.
