// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import Foundation
import IOBluetooth
import BridgeCore

/// A quiet RFCOMM subscription: event frames only, no periodic status requests.
final class BudsController: NSObject, IOBluetoothRFCOMMChannelDelegate {
    var onFrame: ((BudsFrame) -> Void)?
    var onReady: (() -> Void)?
    var onLog: ((String) -> Void)?
    var onClosed: (() -> Void)?
    private var channel: IOBluetoothRFCOMMChannel?
    private var device: IOBluetoothDevice?
    private var stream = BudsStream()
    private var ready = false
    private var stopped = false
    private var opening = false
    private var extendedStatusReady = false
    private var multipointRequested = false
    private let writer = DispatchQueue(label: "dev.budsbridge.controls")
    private var timeout: DispatchWorkItem?
    var connected: Bool { ready && channel?.isOpen() == true }

    func start(address: String) {
        guard let device = IOBluetoothDevice(addressString: address) else { return }
        self.device = device
        onLog?("Buds kontrol ve ses önceliği kanalı açılıyor…")
        let status = device.performSDPQuery(self)
        if status != kIOReturnSuccess { open() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.open() }
        let deadline = DispatchWorkItem { [weak self] in
            guard let self, !self.ready else { return }
            self.onLog?("Buds kontrol kanalı açılamadı."); self.stop(notify: true)
        }
        timeout = deadline; DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: deadline)
    }
    @objc func sdpQueryComplete(_ device: IOBluetoothDevice, status: IOReturn) {
        DispatchQueue.main.async { [weak self] in self?.open() }
    }
    private func open() {
        guard !stopped, !opening, let device else { return }; opening = true
        var uuid = UUID(uuidString: BudsProtocol.serviceUUID)!.uuid
        let parsed = withUnsafeBytes(of: &uuid) { IOBluetoothSDPUUID(bytes: $0.baseAddress!, length: 16) }
        guard let record = device.getServiceRecord(for: parsed) else { onLog?("Buds SPP hizmeti bulunamadı."); stop(notify: true); return }
        var id: BluetoothRFCOMMChannelID = 0
        guard record.getRFCOMMChannelID(&id) == kIOReturnSuccess else { stop(notify: true); return }
        var candidate: IOBluetoothRFCOMMChannel?
        let status = device.openRFCOMMChannelAsync(&candidate, withChannelID: id, delegate: self)
        channel = candidate
        if candidate == nil { onLog?("Kontrol kanalı açılamadı (\(status))."); stop(notify: true); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.becameReady() }
    }
    func rfcommChannelOpenComplete(_ channel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
        DispatchQueue.main.async { [weak self] in self?.becameReady() }
    }
    private func becameReady() {
        guard !stopped, !ready, channel?.isOpen() == true else { return }
        ready = true; timeout?.cancel(); onLog?("Buds kontrol kanalı hazır; durum olayları dinleniyor.")
        onReady?()
        send(id: 0x88, payload: [1, 1, 34])
        send(id: 0x61, payload: [])
        requestInitialMultipoint()
    }
    func send(id: UInt8, payload: [UInt8]) {
        guard !stopped, let channel, connected else { onLog?("Kontrol kanalı bağlı değil."); return }
        let bytes = BudsProtocol.encode(id: id, payload: payload)
        writer.async { [weak self] in
            var data = bytes
            let result = data.withUnsafeMutableBytes { channel.writeSync($0.baseAddress!, length: UInt16($0.count)) }
            DispatchQueue.main.async { [weak self] in
                if result != kIOReturnSuccess { self?.onLog?("Buds komutu gönderilemedi (\(result)).") }
            }
        }
    }
    func rfcommChannelData(_ channel: IOBluetoothRFCOMMChannel!, data pointer: UnsafeMutableRawPointer!, length count: Int) {
        guard let pointer, count > 0 else { return }
        let bytes = Data(bytes: pointer, count: count)
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.stopped else { return }
            for frame in self.stream.append(bytes) {
                if frame.id == 0x61 { self.extendedStatusReady = true; self.requestInitialMultipoint() }
                self.onFrame?(frame)
            }
        }
    }
    func rfcommChannelClosed(_ channel: IOBluetoothRFCOMMChannel!) {
        DispatchQueue.main.async { [weak self] in
            self?.onLog?("Buds kontrol bağlantısı kapandı."); self?.stop(notify: true)
        }
    }
    func stop(notify: Bool = false) {
        guard !stopped else { return }; stopped = true; ready = false; timeout?.cancel()
        channel?.setDelegate(nil); _ = channel?.close(); channel = nil
        if notify { onClosed?() }
    }
    private func requestInitialMultipoint() {
        guard connected, extendedStatusReady, !multipointRequested else { return }
        multipointRequested = true
        // Samsung's d8.g.run/onExtendedStatusReady sends this once per session.
        send(id: 0x76, payload: [])
    }
    deinit { channel?.setDelegate(nil); _ = channel?.close(); timeout?.cancel() }
}
