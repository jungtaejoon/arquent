#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh"
fi

echo "[1/3] rust tests"
cd "$ROOT_DIR/rust_core"
cargo test --all-targets

echo "[2/3] cloud tests + build"
cd "$ROOT_DIR/app/cloud"
npm ci
npm test
npm run build

echo "[3/3] flutter widget tests"
cd "$ROOT_DIR/app/flutter_client"
/Users/taejoonjeong/development/flutter/bin/flutter pub get
/Users/taejoonjeong/development/flutter/bin/flutter test test/widget/ux_flow_test.dart

echo "release preflight passed"
