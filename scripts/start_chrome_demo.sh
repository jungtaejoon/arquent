#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$ROOT_DIR/.run_logs"
PID_DIR="$ROOT_DIR/.run_pids"

mkdir -p "$LOG_DIR" "$PID_DIR"

CLOUD_PORT=4000
WEB_PORT=7362

find_free_port() {
  local port="$1"
  while lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; do
    port=$((port + 1))
  done
  echo "$port"
}

ensure_nvm() {
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
  fi
}

ensure_cloud() {
  if lsof -nP -iTCP:"$CLOUD_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "cloud already running on :$CLOUD_PORT"
    return
  fi

  echo "starting cloud on :$CLOUD_PORT"
  (
    cd "$ROOT_DIR/app/cloud"
    ensure_nvm
    npm run dev >"$LOG_DIR/cloud.log" 2>&1
  ) &
  echo $! >"$PID_DIR/cloud.pid"

  local tries=0
  until curl -s "http://localhost:$CLOUD_PORT/marketplace/recipes" >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [[ $tries -gt 40 ]]; then
      echo "cloud failed to start. see $LOG_DIR/cloud.log"
      exit 1
    fi
    sleep 0.5
  done
}

start_flutter() {
  WEB_PORT="$(find_free_port "$WEB_PORT")"
  echo "starting flutter web on :$WEB_PORT"

  (
    cd "$ROOT_DIR/app/flutter_client"
    /Users/taejoonjeong/development/flutter/bin/flutter run -d chrome --web-port "$WEB_PORT" >"$LOG_DIR/flutter.log" 2>&1
  ) &
  echo $! >"$PID_DIR/flutter.pid"

  local tries=0
  until curl -s "http://localhost:$WEB_PORT" >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [[ $tries -gt 80 ]]; then
      echo "flutter web failed to start. see $LOG_DIR/flutter.log"
      exit 1
    fi
    sleep 0.5
  done

  echo ""
  echo "Demo is running"
  echo "- Cloud:   http://localhost:$CLOUD_PORT"
  echo "- Flutter: http://localhost:$WEB_PORT"
  echo ""
  echo "Open Flutter URL and run: Marketplace -> Refresh -> Install -> Scenario Lab"
}

ensure_cloud
start_flutter
