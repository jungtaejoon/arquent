# Universal Local-First Productivity Automation Platform (v0.3 scaffold)

Monorepo structure:

- `rust_core`: production-focused policy/runtime foundation in Rust
- `app/flutter_client`: Flutter UI scaffold docs
- `app/cloud`: minimal cloud scaffold docs

## Current implementation status

- Rust core models, policy guardrails, sandbox checks, signatures, SQLite migration setup
- Rust FFI endpoint for sensitive runtime proof submission (`arquent_submit_sensitive_runtime_proof`)
- Flutter scaffold with 9 MVP screens, sensitive consent UX, and native MethodChannel stubs
- Cloud minimal API implementation with publish signature validation and webhook rate limiting

## Product design assets

- Killer recipe catalog (v0.3 aligned): `docs/killer-recipes-v0.3.md`
- Ready package templates (10): `recipes/ready-v0.3/`
- Deployment execution guide: `docs/deployment-plan-v0.3.md`

## Recommended production stack (cost-effective)

- Web: Cloudflare Pages
- API: Railway

Preflight and build helpers:

- `./scripts/preflight_release.sh`
- `./scripts/build_web_prod.sh https://<api-domain>`
