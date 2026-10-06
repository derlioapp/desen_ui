#!/usr/bin/env bash
# Renders the example's button scenes with the native macOS engine (Impeller)
# and copies the PNG to the given directory (KALITE S-05).
# Usage: tool/native_snapshot.sh <out-dir> [light|dark]
set -euo pipefail
out=$1; mode=${2:-light}
cd "$(dirname "$0")/../example"
flutter build macos --debug --dart-define=DS_SNAPSHOT=true --dart-define=DS_MODE="$mode" >/dev/null
app=build/macos/Build/Products/Debug/desen_ui_example.app/Contents/MacOS/desen_ui_example
log=$(mktemp)
"$app" >"$log" 2>&1 &
pid=$!
for _ in $(seq 1 30); do
  grep -q DS_SNAPSHOT_PATH "$log" && break
  sleep 1
done
kill "$pid" 2>/dev/null || true
path=$(grep -o 'DS_SNAPSHOT_PATH=[^ ]*' "$log" | cut -d= -f2)
[ -n "$path" ] || { cat "$log"; exit 1; }
grep -o 'Using the Impeller[^.]*' "$log" || true
cp "$path" "$out/"
echo "$out/$(basename "$path")"
