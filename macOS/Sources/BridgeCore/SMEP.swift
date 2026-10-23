// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import Foundation

/// Protocol facts cross-checked against GalaxyBudsClient at commit
/// 754b6fdfb1c151b022cece775c8aaad4eb185afa (GPL-3.0).
public enum SMEP {
    public static let serviceUUID = "f8620674-a1ed-41ab-a8b9-de9ad655729d"
    public static let mdeVersionPayload: [UInt8] = [0x04, 0x03, 0x04, 0, 0, 0x0B, 0x02]
    public static let multipointWrite = encode(command: 0x43, payload: mdeVersionPayload)

    public static func crc<C: Collection>(_ bytes: C) -> UInt16 where C.Element == UInt8 {
        var crc: UInt16 = 0
        for byte in bytes {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 { crc = crc & 0x8000 != 0 ? (crc &<< 1) ^ 0x1021 : crc &<< 1 }
        }
        return crc
    }
    public static func encode(command: UInt8, payload: [UInt8]) -> Data {
        precondition(payload.count <= 1019)
        let body: [UInt8] = [1, command] + payload
        let length = body.count + 2
        let checksum = crc(body)
        return Data([0xFC, UInt8(length & 255), UInt8(length >> 8)] + body +
            [UInt8(checksum & 255), UInt8(checksum >> 8), 0xCC])
    }
}

public struct SMEPFrame: Equatable {
    public let command: UInt8
    public let payload: [UInt8]
    /// This confirms the protocol value, not audio routing or phone coexistence.
    public var reportedAsVersion: UInt8? {
        guard command == 0x45, payload.count >= 10,
              payload.starts(with: [0x02, 0x05, 0x4C, 0x0B]) else { return nil }
        return payload[6]
    }
}

/// Handles RFCOMM's partial/coalesced reads, rejects bad checksums, and bounds memory.
/// A fragmented SMEP frame is not interpreted as a complete notification.
public struct SMEPStream {
    private var buffer: [UInt8] = []
    public init() {}
    public mutating func append(_ data: Data) -> [SMEPFrame] {
        buffer.append(contentsOf: data)
        if buffer.count > 8192 { buffer = Array(buffer.suffix(4096)) }
        var frames: [SMEPFrame] = []
        while let start = buffer.firstIndex(of: 0xFC) {
            if start > 0 { buffer.removeFirst(start) }
            guard buffer.count >= 3 else { break }
            let header = Int(buffer[1]) | Int(buffer[2]) << 8
            let length = header & 0x03FF
            guard length >= 4 else { buffer.removeFirst(); continue }
            let total = length + 4
            guard buffer.count >= total else { break }
            let frame = Array(buffer.prefix(total))
            guard frame.last == 0xCC else { buffer.removeFirst(); continue }
            let body = frame[3..<(total - 3)]
            let checksum = UInt16(frame[total - 3]) | UInt16(frame[total - 2]) << 8
            guard SMEP.crc(body) == checksum else { buffer.removeFirst(); continue }
            buffer.removeFirst(total)
            guard header & 0x2000 == 0, body.first == 1 else { continue }
            frames.append(SMEPFrame(command: frame[4], payload: Array(frame[5..<(total - 3)])))
        }
        if !buffer.contains(0xFC) { buffer.removeAll(keepingCapacity: true) }
        return frames
    }
}

/// One automatic attempt per physical Bluetooth connection, no background polling.
/// An unsuccessful attempt is retried only on a new connection or by the user.
public struct ConnectionGate {
    private var attempted = Set<String>()
    public init() {}
    public mutating func shouldApply(address: String) -> Bool { attempted.insert(address).inserted }
    public mutating func disconnected(address: String) { attempted.remove(address) }
    public mutating func reset() { attempted.removeAll() }
}
