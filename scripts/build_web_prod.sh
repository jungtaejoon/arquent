#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
API_BASE_URL="${1:-}"

if [[ -z "$API_BASE_URL" ]]; then
  echo "usage: ./scripts/build_web_prod.sh https://api.your-domain.com"
  exit 1
fi

cd "$ROOT_DIR/app/flutter_client"
/Users/taejoonjeong/development/flutter/bin/flutter pub get
/Users/taejoonjeong/development/flutter/bin/flutter test test/widget/ux_flow_test.dart
/Users/taejoonjeong/development/flutter/bin/flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"

echo "web build ready: $ROOT_DIR/app/flutter_client/build/web"
