#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# A standard drag-to-Applications installer; no privileged helper or system changes.
set -euo pipefail
APP="${1:?Usage: create-dmg.sh app-path output.dmg getting-started.txt}"
OUTPUT="${2:?Missing output path}"
GUIDE="${3:?Missing getting-started guide}"
NAME="$(basename "$APP" .app)"
case "$NAME" in BudsBridge|TabBridge) ;; *) echo 'Unexpected application bundle' >&2; exit 1;; esac
[ -d "$APP/Contents/MacOS" ] && [ -f "$GUIDE" ]
codesign --verify --deep --strict "$APP"
mkdir -p "$(dirname "$OUTPUT")"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/bridge-dmg.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP" "$STAGE/$NAME.app"
ln -s /Applications "$STAGE/Applications"
cp "$GUIDE" "$STAGE/ÖNCE OKU - READ ME.txt"
hdiutil create -volname "$NAME" -srcfolder "$STAGE" -ov -format UDZO "$OUTPUT"
hdiutil verify "$OUTPUT"
