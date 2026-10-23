// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import Foundation

public struct BudsWidgetSnapshot: Codable, Equatable {
    public var left: Int?
    public var right: Int?
    public var cradle: Int?
    public var noiseMode: Int
    public var connected: Bool
    public var inCall: Bool
    public var updated: Date?
    public init(left: Int? = nil, right: Int? = nil, cradle: Int? = nil, noiseMode: Int = -1,
                connected: Bool = false, inCall: Bool = false, updated: Date? = nil) {
        self.left = left; self.right = right; self.cradle = cradle; self.noiseMode = noiseMode
        self.connected = connected; self.inCall = inCall; self.updated = updated
    }
}
