// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import Foundation

public enum BudsProtocol {
    public static let serviceUUID = "2e73a4ad-332d-41fc-90e2-16bef06523f2"
    public static func encode(id: UInt8, payload: [UInt8], response: Bool = false) -> Data {
        precondition(payload.count <= 1020)
        let body = [id] + payload
        let size = body.count + 2
        let crc = SMEP.crc(body)
        return Data([0xFD, UInt8(size & 255), UInt8(size >> 8) | (response ? 0x10 : 0)] + body +
                    [UInt8(crc & 255), UInt8(crc >> 8), 0xDD])
    }
}

public struct BudsFrame {
    public let id: UInt8
    public let payload: [UInt8]
}

public struct BudsStream {
    private var bytes: [UInt8] = []
    public init() {}
    public mutating func append(_ data: Data) -> [BudsFrame] {
        bytes += data
        if bytes.count > 8192 { bytes = Array(bytes.suffix(4096)) }
        var frames: [BudsFrame] = []
        while let start = bytes.firstIndex(of: 0xFD) {
            if start > 0 { bytes.removeFirst(start) }
            guard bytes.count >= 3 else { break }
            let header = Int(bytes[1]) | Int(bytes[2]) << 8
            let size = header & 0x03FF
            guard size >= 3 else { bytes.removeFirst(); continue }
            let total = size + 4
            guard bytes.count >= total else { break }
            let body = bytes[3..<(total - 3)]
            let crc = UInt16(bytes[total - 3]) | UInt16(bytes[total - 2]) << 8
            guard bytes[total - 1] == 0xDD, SMEP.crc(body) == crc else { bytes.removeFirst(); continue }
            if header & 0x2000 == 0 {
                frames.append(BudsFrame(id: bytes[3], payload: Array(bytes[4..<(total - 3)])))
            }
            bytes.removeFirst(total)
        }
        if !bytes.contains(0xFD) { bytes.removeAll(keepingCapacity: true) }
        return frames
    }
}

public struct MultipointStatus {
    public let supportsMultipoint: Bool
    public let foreground: Bool
    public let streamingMask: UInt8
    public var callActive: Bool { streamingMask & 0x12 != 0 }
    public init?(_ payload: [UInt8]) {
        guard payload.count >= 5 else { return nil }
        supportsMultipoint = payload[1] == 1
        foreground = payload[3] == 0
        streamingMask = payload[4]
    }
}

/// Only a witnessed call transition can trigger automatic audio restoration.
public struct ReturnPolicy {
    public private(set) var inCall = false
    private var shouldRestore = false
    public init() {}
    public mutating func observe(call: Bool, macPreferred: Bool, enabled: Bool) -> Bool {
        if call {
            if !inCall { shouldRestore = macPreferred && enabled }
            inCall = true; return false
        }
        let restore = inCall && shouldRestore && enabled
        inCall = false; shouldRestore = false
        return restore
    }
    public mutating func cancelRestore() { shouldRestore = false }
}
