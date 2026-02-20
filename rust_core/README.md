# rust_core v0.3 MVP

Local-first runtime engine scaffold for recipe evaluation, permission gating, sandbox policy, signature verification, and audit logging.

## Security guardrails included

- Sensitive actions (`camera.capture`, `microphone.record`, `webcam.capture`, `health.read`) enforce user-initiated triggers.
- File operations require `sandbox://` URIs and allowed roots.
- Network actions require allowlisted domains and per-recipe call caps.
- Signature verification uses Ed25519 and SHA-256 package digest.
- Package digest normalization sets `manifest.signature = null` before hashing to avoid circular signature dependency.

## Run tests

```bash
cargo test
```
