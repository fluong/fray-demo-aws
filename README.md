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
| [#1](https://github.com/fluong/fray-demo-aws/pull/1) | Extra `GetSecretValue` on `Resource "*"` → **FR-007** | Not blocking (merge allowed) |
| [#2](https://github.com/fluong/fray-demo-aws/pull/2) | S3 Block Public Access flags cleared → **FR-025** | Blocked (merge refused) |

## License

Apache-2.0 for original files. Third-party Terraform module attributions are in
`infra/NOTICE`.
