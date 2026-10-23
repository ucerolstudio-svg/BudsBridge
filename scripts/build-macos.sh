#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BudsBridge contributors. See LICENSE and LEGAL.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-$ROOT/dist}"
source "$ROOT/scripts/sdk.sh"
SDK="$(select_sdk)"
ARCH="$(uname -m)"
BUILD="$ROOT/macOS/.manual-build"
APP="$DEST/BudsBridge.app"
mkdir -p "$BUILD" "$APP/Contents/MacOS" "$APP/Contents/Resources"
# swiftc also works when the installed SwiftPM framework is unavailable.
xcrun swiftc -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -swift-version 5 -O \
  -parse-as-library -whole-module-optimization -emit-module -emit-object -module-name BridgeCore \
  "$ROOT"/macOS/Sources/BridgeCore/*.swift \
  -o "$BUILD/BridgeCore.o" -emit-module-path "$BUILD/BridgeCore.swiftmodule"
xcrun swiftc -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -swift-version 5 -O \
  -I "$BUILD" "$BUILD/BridgeCore.o" \
  -framework AppKit -framework SwiftUI -framework IOBluetooth -framework CoreBluetooth -framework CoreAudio \
  "$ROOT"/macOS/Sources/BudsBridge/*.swift -o "$APP/Contents/MacOS/BudsBridge"
cp "$ROOT/macOS/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/LICENSE" "$ROOT/THIRD_PARTY_NOTICES.md" "$ROOT/LEGAL.md" "$ROOT/PRIVACY.md" "$APP/Contents/Resources/"
EXT="$APP/Contents/PlugIns/BudsBridgeWidget.appex"
mkdir -p "$EXT/Contents/MacOS"
xcrun swiftc -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -swift-version 5 -O \
  -application-extension -parse-as-library -I "$BUILD" "$BUILD/BridgeCore.o" \
  -framework SwiftUI -framework WidgetKit -framework Foundation \
  -Xlinker -e -Xlinker _NSExtensionMain \
  "$ROOT/macOS/Widget/BudsBridgeWidget.swift" -o "$EXT/Contents/MacOS/BudsBridgeWidget"
cp "$ROOT/macOS/Widget/Info.plist" "$EXT/Contents/Info.plist"
codesign --force --sign - --requirements '=designated => identifier "dev.budsbridge.mac.widget"' --entitlements "$ROOT/macOS/Widget/Entitlements.plist" "$EXT"
codesign --force --sign - --requirements '=designated => identifier "dev.budsbridge.mac"' "$APP"
codesign --verify --deep --strict "$APP"
echo "Built: $APP"
