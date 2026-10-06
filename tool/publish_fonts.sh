#!/bin/sh
# Publishes desen_ui_fonts from a copy outside the repository.
#
# The root .pubignore keeps the fonts out of desen_ui's archive, and pub
# applies a repository's ignore files to a nested package too, so the fonts
# package can't be published in place. This copies the committed package
# (HEAD, so uncommitted edits are not published) to a temporary folder and
# runs pub there.
#
#   tool/publish_fonts.sh --dry-run   # check
#   tool/publish_fonts.sh             # publish
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git -C "$root" archive HEAD desen_ui_fonts | tar -x -C "$tmp"
cd "$tmp/desen_ui_fonts"
dart pub publish "$@"
