# Recipe Signing Tools

Ed25519 signing + verification scripts for `.recipepkg` bundles.

Digest rule implemented by tooling:

- SHA-256 over `manifest.json + flow.json + assets_manifest_hash`
- `manifest.signature` is normalized to `null` during digest generation to avoid circular dependency

## 1) Generate keys

```bash
node recipes/tools/keygen.mjs
```

If `node` command is missing on macOS, install with `nvm` first.

Outputs:

- `recipes/keys/ed25519_private.pem`
- `recipes/keys/ed25519_public.pem`

## 2) Sign packages

```bash
node recipes/tools/sign-packages.mjs --dir=recipes/ready-v0.3 --privateKey=recipes/keys/ed25519_private.pem --updateManifest=true
```

Per package output:

- `signature.sig`
- `manifest.json.signature` updated (optional by flag)

## 3) Verify packages

```bash
node recipes/tools/verify-packages.mjs --dir=recipes/ready-v0.3 --publicKey=recipes/keys/ed25519_public.pem
```

Exit code is non-zero if any package is invalid or missing signature.
