// swift-tools-version: 5.9
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import PackageDescription

let package = Package(
    name: "BudsBridge",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "BudsBridge", targets: ["BudsBridge"])],
    targets: [
        .target(name: "BridgeCore"),
        .executableTarget(name: "BudsBridge", dependencies: ["BridgeCore"]),
        .testTarget(name: "BridgeCoreTests", dependencies: ["BridgeCore"])
    ]
)
