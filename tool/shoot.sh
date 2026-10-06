#!/usr/bin/env bash
# Takes a 2x headless Chrome screenshot of a URL.
# Usage: tool/shoot.sh <url> <out.png> [width] [height] [wait-ms]
# Run shots one at a time: parallel Chrome instances can capture before the
# web fonts load, which renders the fallback font.
set -euo pipefail
url=$1; out=$2; w=${3:-1400}; h=${4:-1300}; wait=${5:-15000}
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$chrome" --headless=new --use-angle=swiftshader --enable-unsafe-swiftshader \
  --hide-scrollbars --force-device-scale-factor=2 --window-size="$w,$h" \
  --virtual-time-budget="$wait" --screenshot="$out" "$url" 2>/dev/null
echo "$out"
