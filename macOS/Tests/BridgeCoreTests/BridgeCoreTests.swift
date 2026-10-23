// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import XCTest
import Foundation
import BridgeCore

final class BridgeCoreTests: XCTestCase {
    func testCapturedWriteVector() {
        XCTAssertEqual(Array(SMEP.multipointWrite), [0xFC, 0x0B, 0, 1, 0x43, 4, 3, 4, 0, 0, 0x0B, 2, 0x1E, 0xAF, 0xCC])
    }
    func testCRCIndependentReference() { XCTAssertEqual(SMEP.crc(Array("123456789".utf8)), 0x31C3) }
    func testEveryChunkBoundary() {
        let data = notification(2)
        for boundary in 0...data.count {
            var stream = SMEPStream()
            let a = stream.append(data.prefix(boundary))
            let b = stream.append(data.dropFirst(boundary))
            XCTAssertEqual((a + b).compactMap(\.reportedAsVersion), [2])
        }
    }
    func testBurstUsesLastVersion() {
        var stream = SMEPStream()
        let frames = stream.append(notification(1) + notification(1) + notification(2) + notification(2))
        XCTAssertEqual(frames.compactMap(\.reportedAsVersion).last, 2)
        XCTAssertEqual(frames.count, 4)
    }
    func testCorruptCRCRejected() {
        var data = notification(2); data[data.count - 3] ^= 1
        var stream = SMEPStream()
        XCTAssertTrue(stream.append(data).isEmpty)
    }
    func testWrongNotificationNotConfirmation() {
        var stream = SMEPStream()
        let data = SMEP.encode(command: 0x44, payload: [2, 5, 0x4C, 0x0B, 0, 0, 2, 0, 0, 0])
        XCTAssertNil(stream.append(data).first?.reportedAsVersion)
    }
    func testShortNotificationNotConfirmation() {
        var stream = SMEPStream()
        let data = SMEP.encode(command: 0x45, payload: [2, 5, 0x4C, 0x0B, 0, 0, 2])
        XCTAssertNil(stream.append(data).first?.reportedAsVersion)
    }
    func testFragmentCannotConfirm() {
        var data = notification(2); data[2] |= 0x20
        var stream = SMEPStream()
        XCTAssertTrue(stream.append(data).isEmpty)
    }
    func testNoiseAndInvalidLengthRecover() {
        var stream = SMEPStream()
        let frames = stream.append(Data([0, 3, 0xFC, 1, 0]) + notification(3))
        XCTAssertEqual(frames.first?.reportedAsVersion, 3)
    }
    func testCorruptFrameThenValidFrameRecover() {
        var bad = notification(2); bad[bad.count - 3] ^= 1
        var stream = SMEPStream()
        XCTAssertEqual(stream.append(bad + notification(3)).compactMap(\.reportedAsVersion), [3])
    }
    func testAutomaticGateRequiresRealReconnect() {
        var gate = ConnectionGate()
        XCTAssertTrue(gate.shouldApply(address: "A"))
        XCTAssertFalse(gate.shouldApply(address: "A"))
        XCTAssertTrue(gate.shouldApply(address: "B"))
        gate.disconnected(address: "A")
        XCTAssertTrue(gate.shouldApply(address: "A"))
        XCTAssertFalse(gate.shouldApply(address: "B"))
    }
    func testRegularProtocolSplitsAndCoalescing() {
        let frame = BudsProtocol.encode(id: 0x76, payload: [0, 1, 0, 1, 2])
        for split in 0...frame.count {
            var decoder = BudsStream()
            let frames = decoder.append(frame.prefix(split)) + decoder.append(frame.dropFirst(split))
            XCTAssertEqual(frames.count, 1)
            XCTAssertEqual(frames.first?.id, 0x76)
            XCTAssertTrue(MultipointStatus(frames[0].payload)!.callActive)
        }
    }
    func testRegularCorruptPacketCannotTriggerReturn() {
        var frame = BudsProtocol.encode(id: 0x76, payload: [0, 1, 0, 1, 0])
        frame[frame.count - 2] ^= 0x80
        var decoder = BudsStream()
        XCTAssertTrue(decoder.append(frame).isEmpty)
    }
    func testBothVoiceTransportsRecognized() {
        XCTAssertTrue(MultipointStatus([0, 1, 0, 1, 2])!.callActive)
        XCTAssertTrue(MultipointStatus([0, 1, 0, 1, 16])!.callActive)
        XCTAssertFalse(MultipointStatus([0, 1, 0, 1, 1])!.callActive)
    }
    func testReturnOnlyAfterOwnedCallEnds() {
        var policy = ReturnPolicy()
        XCTAssertFalse(policy.observe(call: false, macPreferred: true, enabled: true))
        XCTAssertFalse(policy.observe(call: true, macPreferred: true, enabled: true))
        XCTAssertTrue(policy.observe(call: false, macPreferred: false, enabled: true))
        XCTAssertFalse(policy.observe(call: false, macPreferred: true, enabled: true))
    }
    func testDoNotStealCallOrUnownedOutput() {
        var policy = ReturnPolicy()
        XCTAssertFalse(policy.observe(call: true, macPreferred: false, enabled: true))
        XCTAssertFalse(policy.observe(call: false, macPreferred: true, enabled: true))
        XCTAssertFalse(policy.observe(call: true, macPreferred: true, enabled: true))
        XCTAssertFalse(policy.observe(call: true, macPreferred: true, enabled: true))
        policy.cancelRestore()
        XCTAssertFalse(policy.observe(call: false, macPreferred: true, enabled: true))
    }
    private func notification(_ version: UInt8) -> Data {
        SMEP.encode(command: 0x45, payload: [2, 5, 0x4C, 0x0B, 0, 0, version, 0, 0, 0])
    }
    static var allTests: [(String, (BridgeCoreTests) -> () throws -> Void)] {
        [("captured-write-vector", testCapturedWriteVector), ("CRC-reference", testCRCIndependentReference),
         ("all-chunk-boundaries", testEveryChunkBoundary), ("state-burst", testBurstUsesLastVersion),
         ("corrupt-CRC", testCorruptCRCRejected), ("wrong-notification", testWrongNotificationNotConfirmation),
         ("short-notification", testShortNotificationNotConfirmation), ("fragment-rejection", testFragmentCannotConfirm),
         ("noise-recovery", testNoiseAndInvalidLengthRecover), ("corrupt-frame-recovery", testCorruptFrameThenValidFrameRecover),
         ("no-repeated-background-write", testAutomaticGateRequiresRealReconnect),
         ("regular-stream-boundaries", testRegularProtocolSplitsAndCoalescing),
         ("regular-corrupt-rejection", testRegularCorruptPacketCannotTriggerReturn),
         ("classic-and-LE-call-flags", testBothVoiceTransportsRecognized),
         ("return-only-after-call", testReturnOnlyAfterOwnedCallEnds),
         ("no-call-or-output-theft", testDoNotStealCallOrUnownedOutput)]
    }
}
