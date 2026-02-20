#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
API_BASE_URL="${1:-}"

if [[ -z "$API_BASE_URL" ]]; then
  echo "usage: ./scripts/build_web_prod.sh https://api.your-domain.com"
  exit 1
fi

resolve_flutter() {
  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return
  fi
  if [[ -n "${FLUTTER_BIN:-}" && -x "${FLUTTER_BIN}" ]]; then
    echo "${FLUTTER_BIN}"
    return
  fi
  if [[ -x "$HOME/development/flutter/bin/flutter" ]]; then
    echo "$HOME/development/flutter/bin/flutter"
    return
  fi
  if [[ -x "/Users/taejoonjeong/development/flutter/bin/flutter" ]]; then
    echo "/Users/taejoonjeong/development/flutter/bin/flutter"
    return
  fi
  echo ""
}

FLUTTER_CMD="$(resolve_flutter)"
if [[ -z "$FLUTTER_CMD" ]]; then
  echo "flutter not found. Set FLUTTER_BIN or install Flutter in PATH."
  exit 1
fi

cd "$ROOT_DIR/app/flutter_client"
"$FLUTTER_CMD" pub get
"$FLUTTER_CMD" test test/widget/ux_flow_test.dart
"$FLUTTER_CMD" build web --release --dart-define=API_BASE_URL="$API_BASE_URL"

echo "web build ready: $ROOT_DIR/app/flutter_client/build/web"
