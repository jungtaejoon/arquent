#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PID_DIR="$ROOT_DIR/.run_pids"

kill_pid_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local pid
    pid="$(cat "$file")"
    if kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
      echo "stopped pid $pid"
    fi
    rm -f "$file"
  fi
}

kill_pid_file "$PID_DIR/flutter.pid"
kill_pid_file "$PID_DIR/cloud.pid"

echo "done"
