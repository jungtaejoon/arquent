# Real Scenario Runbook (Web + Native)

This runbook is for validating end-user behavior, not only logs.

## A. Chrome real scenarios

1) Start demo services with one command:

```bash
./scripts/start_chrome_demo.sh
```

The script automatically:

- starts cloud API on port 4000 (or reuses existing)
- starts Flutter Chrome app on first available port from 7362
- prints the exact Flutter URL to open

2) Open printed Flutter URL in browser and in app:

- Open `Marketplace` → `Refresh` → Install target recipes
- Open `Scenario Lab` → `Run All + Copy Report`

The report is shown on screen and copied to clipboard as Markdown.

Expected real checks:

- `share-sheet-url-saver`: file write artifact appears
- `desktop-screenshot-mobile-push`: webhook HTTP call succeeds to local cloud
- `mobile-widget-photo-memo`: browser camera permission prompt appears
- `meeting-audio-capture`: browser microphone permission prompt appears

Stop all demo services:

```bash
./scripts/stop_chrome_demo.sh
```

## B. Native mobile sensitive scenarios (iOS/Android)

Native bridge methods are available in this project for:

- `capturePhoto`
- `recordAudio`
- `readHealthDailySummary`

### iOS

```bash
cd app/flutter_client
/Users/taejoonjeong/development/flutter/bin/flutter run -d ios
```

### Android

```bash
cd app/flutter_client
/Users/taejoonjeong/development/flutter/bin/flutter run -d android
```

Then open `Scenario Lab` and run sensitive recipes.

Current native methods return platform payloads for end-to-end connector checks.
Replace those return values with HealthKit/Google Fit integration when production health connector is added.
