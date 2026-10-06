#!/usr/bin/env bash
# Corner benchmark on macOS: builds the example's benchmark in profile mode
# twice, with continuous corners and with plain rounded rectangles
# (DS_PLAIN_CORNERS), runs each, and prints their DS_BENCH lines (frame
# build and raster times in ms). See example/lib/bench/corner_bench_app.dart;
# on a phone, use `flutter run --profile -d <device>` with the same defines.
# Usage: tool/corner_bench.sh [rows]
set -euo pipefail
rows=${1:-300}
cd "$(dirname "$0")/../example"
app=build/macos/Build/Products/Profile/desen_ui_example.app/Contents/MacOS/desen_ui_example
for plain in false true; do
  flutter build macos --profile --dart-define=DS_BENCH=true \
    --dart-define=DS_BENCH_ROWS="$rows" \
    --dart-define=DS_PLAIN_CORNERS="$plain" >/dev/null
  log=$(mktemp)
  "$app" >"$log" 2>&1 &
  pid=$!
  # A warm-up and two recorded round trips of 16 s each, then the report.
  for _ in $(seq 1 90); do
    grep -q DS_BENCH "$log" && break
    sleep 1
  done
  kill "$pid" 2>/dev/null || true
  grep -o 'DS_BENCH .*' "$log" || { cat "$log"; exit 1; }
done
