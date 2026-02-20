# Ready Recipe Packages (v0.3)

This folder contains 10 implementation-ready `.recipepkg` templates.

Each package currently includes:

- `manifest.json`
- `flow.json`

For marketplace publishing, add:

- `assets/` (optional)
- `signature.sig` (Ed25519)

Signing tooling:

- `recipes/tools/keygen.mjs`
- `recipes/tools/sign-packages.mjs`
- `recipes/tools/verify-packages.mjs`

See `recipes/tools/README.md`.

Recommended first launch set:

1. smart-downloads-organizer
2. clipboard-regex-formatter
3. screenshot-rename-move
4. meeting-audio-capture
5. webcam-snapshot-clipboard
6. mobile-widget-photo-memo
7. sleep-summary-morning-alert
8. share-sheet-url-saver
9. pre-meeting-focus-notification
10. desktop-screenshot-mobile-push
