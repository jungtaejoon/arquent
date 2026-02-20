# flutter_client scaffold

Implemented Flutter skeleton for v0.3 with required navigation routes and placeholder screens:

1. Dashboard
2. Builder
3. Trigger setup
4. Action setup
5. Permission review (Sensitive badge + consent)
6. Execution logs (includes Sensitive marker)
7. Import/export
8. Workspace
9. Marketplace (Verified publisher label + risk badge)

## Sensitive UX and runtime handoff

- Pre-run consent gate for Sensitive recipes
- Visible capture UI requirement represented in runtime token payload
- MethodChannel bridge (`arquent.runtime.bridge`) to pass runtime proof to Rust host:
  - method: `submitSensitiveRuntimeProof`
  - payload includes `recipe_id`, `trigger_class`, confirmation token id/time, `visible_capture_ui`

## Native handler stubs

- Android handler stub: `android/app/src/main/kotlin/com/example/flutter_client/MainActivity.kt`
- iOS handler stub: `ios/Runner/AppDelegate.swift`
- macOS handler stub: `macos/Runner/MainFlutterWindow.swift`

Each stub rejects requests when `visible_capture_ui == false` and returns `ok` only for valid sensitive proof payloads.

## Local run (once Flutter SDK is installed)

```bash
cd app/flutter_client
flutter pub get
flutter run
```

## End-to-end demo in Chrome (share → install → run)

1) Start cloud API:

```bash
cd app/cloud
npm install
npm run dev
```

2) Start Flutter web app:

```bash
cd app/flutter_client
flutter pub get
flutter run -d chrome --web-port 7360
```

3) In app UI:

- Open `Marketplace`
- Click `Publish Demo Recipe`
- Click `Refresh`
- Click `Install`
- Open `Dashboard`
- Click `Run Local`
- Open `Execution Logs` and verify a new `success` entry

This demonstrates the full local-first cycle: recipe publish to marketplace, client install, and on-device execution.

## What executes in Chrome demo right now

Real execution in local runtime:

- `notification.send`
- `file.write`, `file.move`, `file.rename` (sandbox map)
- `clipboard.read`, `clipboard.write`
- `http.request` (to local cloud endpoints)
- trigger/condition evaluation + detailed run logs

Policy-safe simulated execution (web constraints):

- `camera.capture`, `microphone.record`, `webcam.capture`
- `health.read`
- transform actions (`ocr`, `speech_to_text`, `qr_decode`)

Recommended recipes to verify immediately:

- `share-sheet-url-saver`
- `pre-meeting-focus-notification`
- `desktop-screenshot-mobile-push`
- `hotkey-work-mode-launcher`

## Scenario Lab (real execution checks)

Open `Scenario Lab` and run:

1. `Prepare (Install Scenarios)`
2. Run each scenario button

Expected real behavior:

- `share-sheet-url-saver`: file sandbox write is created
- `desktop-screenshot-mobile-push`: actual HTTP request hits local cloud webhook
- `mobile-widget-photo-memo`: browser asks camera permission, stream opens/stops
- `meeting-audio-capture`: browser asks microphone permission, stream opens/stops

Health limitation:

- `sleep-summary-morning-alert` is blocked on web for real health data
- run this scenario on iOS/Android native build for real connector behavior

For full real-execution procedure, see `docs/real-scenario-runbook.md`.

## UX test run

```bash
cd app/flutter_client
flutter test test/widget/ux_flow_test.dart
```

This test suite covers:

- Dashboard quick-run visibility
- Sensitive permission consent gating
- MethodChannel proof submission success path
- Marketplace Sensitive badge + Verified labels

## Production web build (Cloudflare Pages)

Build with production API URL:

```bash
./scripts/build_web_prod.sh https://<your-api-domain>
```

If using Cloudflare Pages Git build:

- Build command: `./scripts/build_web_prod.sh https://<your-api-domain>`
- Output directory: `app/flutter_client/build/web`
