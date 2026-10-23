#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BudsBridge contributors. See LICENSE and LEGAL.md.
# Select a compatible installed SDK without changing xcode-select globally.
select_sdk() {
  if [ -n "${BUDSBRIDGE_SDK:-}" ]; then printf '%s\n' "$BUDSBRIDGE_SDK"; return; fi
  local preferred="${SDKROOT:-$(xcrun --show-sdk-path)}"
  if printf 'import Foundation\n' | xcrun swiftc -sdk "$preferred" -typecheck - >/dev/null 2>&1; then
    printf '%s\n' "$preferred"; return
  fi
  local candidate
  for candidate in "$(dirname "$preferred")"/MacOSX[0-9]*.sdk; do
    [ -d "$candidate" ] && [ ! -L "$candidate" ] || continue
    if printf 'import Foundation\n' | xcrun swiftc -sdk "$candidate" -typecheck - >/dev/null 2>&1; then
      printf '%s\n' "$candidate"; return
    fi
  done
  echo 'No compatible SDK found. Set BUDSBRIDGE_SDK to a matching installed macOS SDK.' >&2
  return 1
}
