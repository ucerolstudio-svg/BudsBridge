#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BudsBridge contributors. See LICENSE and LEGAL.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/sdk.sh"
SDK="$(select_sdk)"
BUILD="$ROOT/macOS/.test-build"
mkdir -p "$BUILD"
xcrun swiftc -sdk "$SDK" -swift-version 5 -parse-as-library -whole-module-optimization -emit-module -emit-object \
  -module-name BridgeCore "$ROOT"/macOS/Sources/BridgeCore/*.swift \
  -o "$BUILD/BridgeCore.o" -emit-module-path "$BUILD/BridgeCore.swiftmodule"
# The Command Line Tools distribution need not include XCTest. Run the same
# test methods with ordinary debug assertions in that environment.
cat > "$BUILD/Assertions.swift" <<'SWIFT'
import Foundation
class XCTestCase {}
func XCTAssertEqual<T: Equatable>(_ a: T, _ b: T) { precondition(a == b, "Expected \(b), got \(a)") }
func XCTAssertTrue(_ condition: Bool) { precondition(condition, "Expected true") }
func XCTAssertFalse(_ condition: Bool) { precondition(!condition, "Expected false") }
func XCTAssertNil<T>(_ value: T?) { precondition(value == nil, "Expected nil") }
SWIFT
sed '/^import XCTest$/d' "$ROOT/macOS/Tests/BridgeCoreTests/BridgeCoreTests.swift" > "$BUILD/BridgeCoreChecks.swift"
cat > "$BUILD/main.swift" <<'SWIFT'
let suite = BridgeCoreTests()
for (name, test) in BridgeCoreTests.allTests { try test(suite)(); print("PASS \(name)") }
print("\(BridgeCoreTests.allTests.count) protocol checks passed")
SWIFT
xcrun swiftc -sdk "$SDK" -swift-version 5 -I "$BUILD" "$BUILD/BridgeCore.o" \
  "$BUILD/Assertions.swift" "$BUILD/BridgeCoreChecks.swift" "$BUILD/main.swift" -o "$BUILD/Tests"
"$BUILD/Tests"
