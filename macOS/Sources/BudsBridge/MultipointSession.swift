// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import Foundation
import IOBluetooth
import BridgeCore

enum PatchResult {
    case verified(UInt8)
    case writtenUnconfirmed
    case failed(String)
}

/// Changes a live peer record over SMEP. The serial channel is closed after the
/// response window; no firmware, account database or Bluetooth pairing is modified.
final class MultipointSession: NSObject, IOBluetoothRFCOMMChannelDelegate {
    var onLog: ((String) -> Void)?
    private var completion: ((PatchResult) -> Void)?
    private var device: IOBluetoothDevice?
    private var channel: IOBluetoothRFCOMMChannel?
    private var stream = SMEPStream()
    private var reportedVersion: UInt8?
    private var opening = false
    private var sent = false
    private var attempts = 0
    private var finished = false
    private var deadline: DispatchWorkItem?
    private let writer = DispatchQueue(label: "dev.budsbridge.smep-write")

    func start(address: String, completion: @escaping (PatchResult) -> Void) {
        self.completion = completion
        guard let device = IOBluetoothDevice(addressString: address), device.isPaired(),
              device.isConnected() || AudioRouting.matching(name: device.name ?? "", address: address) != nil else {
            finish(.failed("Önce kulaklığı Mac’e bağla.")); return
        }
        self.device = device
        onLog?("SMEP hizmeti aranıyor…")
        let deadline = DispatchWorkItem { [weak self] in self?.finish(.failed("SMEP işlemi zaman aşımına uğradı.")) }
        self.deadline = deadline
        DispatchQueue.main.asyncAfter(deadline: .now() + 24, execute: deadline)
        let status = device.performSDPQuery(self)
        if status != kIOReturnSuccess { openChannel() }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in self?.openChannel() }
        }
    }
    @objc func sdpQueryComplete(_ device: IOBluetoothDevice, status: IOReturn) {
        DispatchQueue.main.async { [weak self] in self?.openChannel() }
    }
    private func openChannel() {
        guard !finished, !opening, !sent, let device else { return }
        opening = true
        var uuid = UUID(uuidString: SMEP.serviceUUID)!.uuid
        let parsed = withUnsafeBytes(of: &uuid) { IOBluetoothSDPUUID(bytes: $0.baseAddress!, length: 16) }
        guard let service = device.getServiceRecord(for: parsed) else {
            finish(.failed("Bu bağlantıda SMEP hizmeti bulunamadı. Kulaklığı yeniden bağlayıp dene.")); return
        }
        var channelID: BluetoothRFCOMMChannelID = 0
        let status = service.getRFCOMMChannelID(&channelID)
        guard status == kIOReturnSuccess, channelID != 0 else {
            finish(.failed("SMEP kanal numarası alınamadı (\(status)).")); return
        }
        attempts += 1
        onLog?("SMEP RFCOMM kanalı açılıyor (\(attempts)/3)…")
        var candidate: IOBluetoothRFCOMMChannel?
        let result = device.openRFCOMMChannelAsync(&candidate, withChannelID: channelID, delegate: self)
        channel = candidate
        if candidate == nil { retry("Kanal açılamadı (\(result))."); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, !self.finished, !self.sent else { return }
            if self.channel?.isOpen() == true { self.write() }
            else { self.retry("SMEP kanalı yanıt vermedi.") }
        }
    }
    func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.finished, self.channel === rfcommChannel else { return }
            if rfcommChannel.isOpen() { self.write() }
        }
    }
    private func retry(_ reason: String) {
        guard !finished, !sent else { return }
        channel?.setDelegate(nil); _ = channel?.close(); channel = nil
        guard attempts < 3 else { finish(.failed(reason)); return }
        onLog?(reason + " Yeniden denenecek…")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, !self.finished else { return }
            self.opening = false; self.openChannel()
        }
    }
    private func write() {
        guard !finished, !sent, let channel, channel.isOpen() else { return }
        sent = true
        onLog?("MDE_VERSION asVer=2 gönderiliyor (15 bayt)…")
        writer.async { [weak self] in
            var data = SMEP.multipointWrite
            let result = data.withUnsafeMutableBytes { channel.writeSync($0.baseAddress!, length: UInt16($0.count)) }
            DispatchQueue.main.async {
                guard let self, !self.finished else { return }
                guard result == kIOReturnSuccess else { self.finish(.failed("Komut gönderilemedi (\(result)).")); return }
                self.onLog?("Komut gönderildi. Kulaklığın durum cevabı bekleniyor…")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    guard let self, !self.finished else { return }
                    if let version = self.reportedVersion {
                        self.finish(version == 2 || version == 3 ? .verified(version) : .failed("Kulaklık asVer=\(version) bildirdi; etkinleşme doğrulanamadı."))
                    } else { self.finish(.writtenUnconfirmed) }
                }
            }
        }
    }
    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        guard let dataPointer, dataLength > 0 else { return }
        let bytes = Data(bytes: dataPointer, count: dataLength)
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.finished, self.channel === rfcommChannel else { return }
            for frame in self.stream.append(bytes) {
                if let version = frame.reportedAsVersion, self.sent {
                    self.reportedVersion = version
                    self.onLog?("Kulaklıktan durum cevabı: asVer=\(version)")
                }
            }
        }
    }
    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.finished, self.channel === rfcommChannel else { return }
            self.finish(.failed("Kulaklık SMEP kanalını kapattı."))
        }
    }
    func cancel() { finish(.failed("İşlem iptal edildi.")) }
    private func finish(_ result: PatchResult) {
        guard !finished else { return }; finished = true
        deadline?.cancel(); deadline = nil
        channel?.setDelegate(nil); _ = channel?.close(); channel = nil
        let callback = completion; completion = nil; callback?(result)
    }
}
