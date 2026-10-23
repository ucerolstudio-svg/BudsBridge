// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import AppKit
import SwiftUI
import IOBluetooth
import CoreBluetooth
import CoreAudio
import BridgeCore
import WidgetKit

struct Headphones: Identifiable {
    let id: String
    let name: String
    let connected: Bool
    var supportedName: Bool {
        name.localizedCaseInsensitiveContains("Buds3 Pro")
    }
}

final class BridgeModel: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var devices: [Headphones] = []
    @Published var selectedID = "" {
        didSet {
            if !preview {
                UserDefaults.standard.set(selectedID, forKey: "selected-device")
                if oldValue != selectedID { changedSelection() }
            }
        }
    }
    @Published var message = "Kulaklığı Mac’le eşleştir, ardından Bluetooth iznini ver."
    @Published var protocolStatus = "Henüz denenmedi"
    @Published var busy = false
    @Published var automatic = false
    @Published var outputName = ""
    @Published var log: [String] = []
    @Published var controlsConnected = false
    @Published var callActive = false
    @Published var returnToMac = true
    @Published var batteryLeft: Int?
    @Published var batteryRight: Int?
    @Published var batteryCase: Int?
    @Published var noiseMode = -1
    @Published var equalizer = -1
    @Published var customBands = [Double](repeating: 0, count: 9)
    @Published var customEQAvailable = false
    @Published var featureValues: [String: Bool] = [:]
    @Published var touchEnabled = [Bool](repeating: true, count: 7)
    @Published var settingsKnown = false
    @Published var controlMessage = "Kontrol kanalı henüz bağlı değil."
    @Published var batteryUpdated: Date?
    let preview: Bool
    private var central: CBCentralManager?
    private var session: MultipointSession?
    private var connectNotification: IOBluetoothUserNotification?
    private var disconnectNotifications: [String: IOBluetoothUserNotification] = [:]
    private var gate = ConnectionGate()
    private let worker = DispatchQueue(label: "dev.budsbridge.connection")
    private var lastObserved: [String: Bool] = [:]
    private var controller: BudsController?
    private var returnPolicy = ReturnPolicy()
    private var prefersBuds = false
    private var lastBudsOutput = Date.distantPast
    private var returnGeneration = 0
    private var audioListener: AudioObjectPropertyListenerBlock?
    private var watchedAudioDevices = Set<AudioDeviceID>()
    private var idleClose: DispatchWorkItem?
    private var pendingCommands: [(UInt8, [UInt8], String)] = []
    private var lastWidgetSnapshot: BudsWidgetSnapshot?
    private var widgetReload: DispatchWorkItem?
    private var controllerEpoch = 0
    private var monitorRecoveryAttempts = 0
    private var previousOutputWasBuds = false

    init(preview: Bool = false) {
        self.preview = preview
        super.init()
        if preview {
            devices = [.init(id: "preview", name: "Galaxy Buds3 Pro", connected: true)]
            selectedID = "preview"; outputName = "Galaxy Buds3 Pro"
            message = "Arayüz önizlemesi · Bluetooth işlemleri kapalı"
            return
        }
        selectedID = UserDefaults.standard.string(forKey: "selected-device") ?? ""
        automatic = UserDefaults.standard.bool(forKey: "automatic-smep")
        returnToMac = UserDefaults.standard.object(forKey: "return-to-mac") as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: "widget-snapshot"),
           let saved = try? JSONDecoder().decode(BudsWidgetSnapshot.self, from: data) {
            batteryLeft = saved.left; batteryRight = saved.right; batteryCase = saved.cradle
            noiseMode = saved.noiseMode; batteryUpdated = saved.updated
        }
        installAudioListener()
        NotificationCenter.default.addObserver(self, selector: #selector(wokeUp),
            name: NSApplication.didBecomeActiveNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wokeUp), name: NSWorkspace.didWakeNotification, object: nil)
        requestBluetooth()
    }
    var selected: Headphones? { devices.first { $0.id == selectedID } }
    var canApply: Bool { selected?.connected == true && selected?.supportedName == true && !busy && !callActive && !preview }
    func addLog(_ text: String) {
        let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        log.append("\(stamp)  \(text)")
        if log.count > 80 { log.removeFirst(log.count - 80) }
        let arguments = CommandLine.arguments
        if let flag = arguments.firstIndex(of: "--diagnostics"), arguments.indices.contains(flag + 1) {
            try? log.joined(separator: "\n").write(toFile: arguments[flag + 1], atomically: true, encoding: .utf8)
        }
    }
    func requestBluetooth() {
        guard !preview else { return }
        if central == nil { central = CBCentralManager(delegate: self, queue: .main) }
        if CBManager.authorization == .allowedAlways {
            if connectNotification == nil {
                connectNotification = IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(deviceConnected(_:device:)))
            }
            refresh()
            scheduleAutomatic()
            if !automatic { startControls() }
        }
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unauthorized: message = "Sistem Ayarları → Gizlilik ve Güvenlik → Bluetooth: BudsBridge’e izin ver."
        case .poweredOff: message = "Mac’in Bluetooth bağlantısını aç."
        case .poweredOn: requestBluetooth()
        default: break
        }
    }
    @objc private func wokeUp() { refresh() }
    func refresh() {
        guard !preview, CBManager.authorization == .allowedAlways else { return }
        outputName = AudioRouting.string(AudioRouting.current(), kAudioObjectPropertyName)
        let paired = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? [])
            .filter { ($0.name ?? "").localizedCaseInsensitiveContains("buds") }
        devices = paired.compactMap { device in
            guard let address = device.addressString, let name = device.name else { return nil }
            if disconnectNotifications[address] == nil {
                disconnectNotifications[address] = device.register(forDisconnectNotification: self, selector: #selector(deviceDisconnected(_:device:)))
            }
            let connected = device.isConnected() || AudioRouting.matching(name: name, address: address) != nil
            if lastObserved[address] == true && !connected { gate.disconnected(address: address) }
            lastObserved[address] = connected
            return .init(id: address, name: name, connected: connected)
        }.sorted { $0.name < $1.name }
        if selectedID.isEmpty || !devices.contains(where: { $0.id == selectedID }) {
            selectedID = devices.first(where: \.supportedName)?.id ?? devices.first?.id ?? ""
        }
        if let audioListener {
            let outputs = AudioRouting.outputs().filter { $0.bluetooth }
            let liveIDs = Set(outputs.map(\.id))
            for id in watchedAudioDevices.subtracting(liveIDs) {
                var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                    mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
                _ = AudioObjectRemovePropertyListenerBlock(id, &address, .main, audioListener)
                watchedAudioDevices.remove(id)
            }
            for output in outputs where !watchedAudioDevices.contains(output.id) {
                var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                    mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
                if AudioObjectAddPropertyListenerBlock(output.id, &address, .main, audioListener) == noErr {
                    watchedAudioDevices.insert(output.id)
                }
            }
        }
        exportWidgetSnapshot()
    }
    @objc func deviceConnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.refresh()
            if device.addressString == self.selectedID { self.scheduleAutomatic() }
            if !self.automatic { self.startControls() }
        }
    }
    @objc func deviceDisconnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let address = device.addressString else { return }
            if address == self.selectedID {
                // Audio and the legacy IOBluetooth connection cache can disagree.
                // A delayed confirmation avoids cancelling a live SMEP session.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self else { return }; self.refresh()
                    if self.selected?.connected != true {
                        self.gate.disconnected(address: address)
                        self.session?.cancel(); self.session = nil
                        self.protocolStatus = "Bağlantı kesildi · sonraki bağlantıda yeniden uygulanmalı"
                    }
                }
            }
            self.refresh()
        }
    }
    func setAutomatic(_ enabled: Bool) {
        automatic = enabled; UserDefaults.standard.set(enabled, forKey: "automatic-smep")
        if enabled { gate.reset(); requestBluetooth(); scheduleAutomatic() }
    }
    private func scheduleAutomatic() {
        guard automatic, !preview else { return }
        let address = selectedID
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, self.automatic, self.selectedID == address else { return }
            self.refresh()
            guard self.canApply, self.gate.shouldApply(address: address) else { return }
            self.apply()
        }
    }
    func apply() {
        guard canApply, let selected else { return }
        _ = gate.shouldApply(address: selected.id)
        controller?.stop(); controller = nil; controlsConnected = false
        busy = true; protocolStatus = "Protokol cevabı bekleniyor…"
        message = "Kulaklıkla doğrudan Bluetooth üzerinden görüşülüyor."
        let session = MultipointSession(); self.session = session
        session.onLog = { [weak self] in self?.addLog($0) }
        session.start(address: selected.id) { [weak self] result in
            guard let self else { return }
            self.busy = false; self.session = nil
            switch result {
            case .verified(let version):
                self.protocolStatus = "Protokol onayı alındı · asVer=\(version)"
                self.message = "Telefondan da Buds’a bağlan. İki cihazın bağlantısı birlikte kalmalı; ardından arama geçişini dene."
            case .writtenUnconfirmed:
                self.protocolStatus = "Komut gönderildi · kulaklıktan onay alınamadı"
                self.message = "Etkinleştiği doğrulanmadı. Telefon ve Mac’te Bluetooth bağlantısını kontrol et."
            case .failed(let reason):
                self.protocolStatus = "Doğrulanamadı"; self.message = reason
            }
            self.addLog(self.protocolStatus); self.refresh()
            self.startControls()
        }
    }
    func connect() {
        guard !preview, !busy, let selected else { return }
        busy = true; message = "Mac’e bağlanıyor…"
        worker.async { [weak self] in
            guard let device = IOBluetoothDevice(addressString: selected.id) else { return }
            let result = device.isConnected() ? kIOReturnSuccess : device.openConnection(nil, withPageTimeout: 8192, authenticationRequired: false)
            DispatchQueue.main.async {
                guard let self else { return }
                self.busy = false; self.refresh()
                if result == kIOReturnSuccess || device.isConnected() {
                    self.message = "Mac bağlantısı kuruldu."
                    if let output = AudioRouting.matching(name: selected.name, address: selected.id) { _ = AudioRouting.select(output.id) }
                    self.prefersBuds = true
                    self.scheduleAutomatic()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.refresh(); self?.scheduleAutomatic() }
                } else { self.message = "Mac’e bağlanamadı (\(result)). Bluetooth ayarlarından Bağlan’ı dene."; self.addLog(self.message) }
            }
        }
    }
    func release() {
        guard !preview, !busy, let selected else { return }
        returnPolicy.cancelRestore(); returnGeneration += 1; prefersBuds = false
        controller?.stop(); controller = nil; controlsConnected = false
        busy = true
        worker.async { [weak self] in
            let device = IOBluetoothDevice(addressString: selected.id)
            let result = device?.closeConnection() ?? kIOReturnNotFound
            DispatchQueue.main.async {
                self?.busy = false; self?.refresh()
                self?.message = result == kIOReturnSuccess ? "Mac bağlantısı bırakıldı." : "Bağlantı bırakılamadı (\(result))."
            }
        }
    }
    func bluetoothSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") { NSWorkspace.shared.open(url) }
    }
    func copyLog() {
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(log.joined(separator: "\n"), forType: .string)
    }
    private func installAudioListener() {
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.audioChanged() }
        audioListener = listener
        for selector in [kAudioHardwarePropertyDefaultOutputDevice, kAudioHardwarePropertyDevices] {
            var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain)
            _ = AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, listener)
        }
    }
    private func audioChanged() {
        refresh()
        guard let selected else { return }
        let output = AudioRouting.matching(name: selected.name, address: selected.id)
        let usesBuds = output?.id == AudioRouting.current()
        let fellBackFromBuds = previousOutputWasBuds && !usesBuds
        previousOutputWasBuds = usesBuds
        if usesBuds { prefersBuds = true; lastBudsOutput = Date() }
        else if !callActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self, !self.callActive, let selected = self.selected else { return }
                if let output = AudioRouting.matching(name: selected.name, address: selected.id), output.id != AudioRouting.current() {
                    self.prefersBuds = false
                }
            }
        }
        if let output, AudioRouting.isRunning(output.id) { idleClose?.cancel(); startControls() }
        else { scheduleIdleClose() }
        if fellBackFromBuds && returnToMac { startControls() }
    }
    func startControls() {
        guard !preview, !busy, controller == nil, let selected, selected.supportedName,
              selected.connected || callActive else { return }
        if AudioRouting.matching(name: selected.name, address: selected.id)?.id == AudioRouting.current() {
            prefersBuds = true; lastBudsOutput = Date()
        }
        let controller = BudsController(); self.controller = controller
        controllerEpoch += 1
        let epoch = controllerEpoch, address = selected.id
        controller.onLog = { [weak self] in self?.addLog($0) }
        controller.onReady = { [weak self] in
            guard let self else { return }
            guard self.controllerEpoch == epoch, self.selectedID == address else { return }
            self.controlsConnected = true; self.controlMessage = "Kulaklık durum olayları dinleniyor."
            let pending = self.pendingCommands; self.pendingCommands.removeAll()
            for (id, payload, label) in pending { self.command(id, payload, label: label) }
            self.scheduleIdleClose()
        }
        controller.onClosed = { [weak self] in
            guard let self, self.controllerEpoch == epoch, self.selectedID == address else { return }
            self.controlsConnected = false; self.controller = nil; self.pendingCommands.removeAll()
            if self.callActive && self.monitorRecoveryAttempts < 1 {
                self.monitorRecoveryAttempts += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self, self.controllerEpoch == epoch, self.selectedID == address else { return }
                    self.startControls()
                }
            }
        }
        controller.onFrame = { [weak self] frame in
            guard let self, self.controllerEpoch == epoch, self.selectedID == address else { return }
            self.received(frame)
        }
        controller.start(address: selected.id)
    }
    private func received(_ frame: BudsFrame) {
        defer { exportWidgetSnapshot() }
        let p = frame.payload
        switch frame.id {
        case 0x76:
            guard let status = MultipointStatus(p) else { return }
            addLog("Ses önceliği: arama=\(status.callActive), önplan=\(status.foreground), maske=\(status.streamingMask)")
            let wasInCall = callActive
            let restore = returnPolicy.observe(call: status.callActive,
                macPreferred: prefersBuds || Date().timeIntervalSince(lastBudsOutput) < 5, enabled: returnToMac)
            callActive = returnPolicy.inCall
            if callActive {
                returnGeneration += 1
                if !wasInCall { monitorRecoveryAttempts = 0 }
                controlMessage = "Telefonda arama var; Mac’e dönüş bekletiliyor."
            }
            if restore {
                returnGeneration += 1
                let generation = returnGeneration, address = selectedID
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.restoreOutput(generation: generation, originalAddress: address)
                }
            }
            scheduleIdleClose()
        case 0x60 where p.count >= 7:
            batteryUpdated = Date()
            batteryLeft = battery(p[1]); batteryRight = battery(p[2]); batteryCase = battery(p[6])
        case 0x61 where p.count >= 34:
            batteryUpdated = Date()
            batteryLeft = battery(p[2]); batteryRight = battery(p[3]); batteryCase = battery(p[7])
            equalizer = Int(p[9]); noiseMode = Int(p[12])
            touchEnabled = [p[10] & 128 != 0, p[10] & 8 != 0, p[10] & 4 != 0, p[10] & 2 != 0,
                            p[10] & 1 != 0, p[10] & 16 != 0, p[10] & 32 != 0]
            featureValues["voice"] = p[26] == 1; featureValues["onebud"] = p[28] == 1
            featureValues["sidetone"] = p[33] == 1; featureValues["seamless"] = p[19] == 0
            if p.count > 43 { featureValues["clearcall"] = p[43] == 1 }
            if p.count > 45 { featureValues["autopause"] = p[45] == 1 }
            if p.count > 49 { featureValues["adaptivevolume"] = p[49] == 1 }
            if p.count > 52 { featureValues["siren"] = p[52] == 1 }
            settingsKnown = true; controlMessage = "Kulaklıktan güncel ayarlar alındı."
            addLog("Durum: pil \(batteryLeft.map(String.init) ?? "?")/\(batteryRight.map(String.init) ?? "?"), gürültü=\(noiseMode), EQ=\(equalizer)")
        case 0x77 where !p.isEmpty: noiseMode = Int(p[0])
        case 0x69 where p.count >= 2:
            let presets = Int(p[0]), bands = Int(p[1]), offset = 2 + max(0, presets - 1) * Int(p[1])
            if presets >= 1, bands == 9, offset + bands <= p.count {
                customEQAvailable = true
                customBands = p[offset..<(offset + bands)].map { Double(Int8(bitPattern: $0)) }
            }
        case 0x51 where p.count >= 2:
            controlMessage = p[1] == 0 ? "Kulaklık komutu kabul etti." : "Kulaklık komutu reddetti (\(p[1]))."
            addLog("Komut cevabı: id=\(p[0]), sonuç=\(p[1])")
            if p[1] == 0 { controller?.send(id: 0x61, payload: []) }
        default: break
        }
    }
    private func battery(_ value: UInt8) -> Int? { value <= 100 ? Int(value) : nil }
    func restoreOutput(attempt: Int = 0, generation: Int? = nil, originalAddress: String? = nil) {
        let token = generation ?? { returnGeneration += 1; return returnGeneration }()
        guard !preview, !callActive, token == returnGeneration, let selected else { return }
        let address = originalAddress ?? selected.id
        guard selected.id == address else { return }
        if let output = AudioRouting.matching(name: selected.name, address: selected.id) {
            let status = AudioRouting.select(output.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, !self.callActive, token == self.returnGeneration, self.selectedID == address else { return }
                if status == noErr && AudioRouting.current() == output.id {
                    self.refresh(); self.prefersBuds = true; self.controlMessage = "Mac’in ses çıkışı Buds’a geri alındı."
                    self.addLog(self.controlMessage)
                } else if attempt < 12 { self.restoreOutput(attempt: attempt + 1, generation: token, originalAddress: address) }
                else { self.controlMessage = "Ses çıkışı geri alınamadı (\(status))."; self.addLog(self.controlMessage) }
            }
        } else if attempt < 12 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.restoreOutput(attempt: attempt + 1, generation: token, originalAddress: address) }
        } else { controlMessage = "Buds ses çıkışı henüz görünmüyor. Mac’e bağlan düğmesini dene."; addLog(controlMessage) }
    }
    func setReturnToMac(_ enabled: Bool) {
        returnToMac = enabled; UserDefaults.standard.set(enabled, forKey: "return-to-mac")
        if !enabled { returnPolicy.cancelRestore(); returnGeneration += 1 }
    }
    func command(_ id: UInt8, _ payload: [UInt8], label: String) {
        guard !preview, !busy, selected?.supportedName == true else { return }
        guard controlsConnected else {
            guard selected?.connected == true else { controlMessage = "Önce kulaklığı Mac’e bağla."; return }
            if pendingCommands.count < 8 { pendingCommands.append((id, payload, label)) }
            controlMessage = "Kontrol kanalı komut için açılıyor…"; startControls(); return
        }
        controlMessage = "\(label): komut gönderildi, kulaklık cevabı bekleniyor."
        controller?.send(id: id, payload: payload)
        scheduleIdleClose()
    }
    func setNoise(_ mode: Int) { guard (0...3).contains(mode) else { return }; command(0x78, [UInt8(mode)], label: "Gürültü kontrolü") }
    func setEQ(_ mode: Int) { guard (0...6).contains(mode) else { return }; command(0x86, [UInt8(mode)], label: "Ekolayzır") }
    func readCustomEQ() { command(0x69, [], label: "Özel EQ bilgisi") }
    func applyCustomEQ() {
        guard customEQAvailable else { return }
        let bands = customBands.map { UInt8(bitPattern: Int8(max(-10, min(10, Int($0.rounded()))))) }
        command(0x89, [9] + bands, label: "9 bant EQ")
        command(0x86, [6], label: "Özel EQ modu")
    }
    func setTouch(_ index: Int, _ enabled: Bool) {
        guard settingsKnown, touchEnabled.indices.contains(index) else { return }
        var next = touchEnabled; next[index] = enabled
        command(0x90, next.map { $0 ? 1 : 0 }, label: "Dokunma kontrolleri")
    }
    func setFeature(_ key: String, _ enabled: Bool) {
        let ids: [String: UInt8] = ["voice":0x7A, "onebud":0x6F, "sidetone":0x8B, "seamless":0xAF,
                                   "clearcall":0x48, "autopause":0x6C, "adaptivevolume":0xC5, "siren":0xDE]
        guard let id = ids[key], featureValues[key] != nil else { return }
        command(id, [(key == "seamless" ? !enabled : enabled) ? 1 : 0], label: "Kulaklık ayarı")
    }
    private func scheduleIdleClose() {
        idleClose?.cancel()
        guard !callActive, let selected else { return }
        if let output = AudioRouting.matching(name: selected.name, address: selected.id), AudioRouting.isRunning(output.id) { return }
        let close = DispatchWorkItem { [weak self] in
            guard let self, !self.callActive, let selected = self.selected else { return }
            if let output = AudioRouting.matching(name: selected.name, address: selected.id), AudioRouting.isRunning(output.id) { return }
            self.controller?.stop(); self.controller = nil; self.controlsConnected = false
            self.controlMessage = "Pil tasarrufu · son bilinen değerler gösteriliyor."
            self.addLog("Ses ve arama yok; kontrol kanalı pil tasarrufu için kapatıldı.")
        }
        idleClose = close; DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: close)
    }
    private func exportWidgetSnapshot() {
        guard !preview else { return }
        let snapshot = BudsWidgetSnapshot(left: batteryLeft, right: batteryRight, cradle: batteryCase,
            noiseMode: noiseMode, connected: selected?.connected ?? false, inCall: callActive, updated: batteryUpdated)
        guard snapshot != lastWidgetSnapshot, let data = try? JSONEncoder().encode(snapshot) else { return }
        lastWidgetSnapshot = snapshot
        UserDefaults.standard.set(data, forKey: "widget-snapshot")
        widgetReload?.cancel()
        let reload = DispatchWorkItem { WidgetCenter.shared.reloadTimelines(ofKind: "BudsBridgeSmall") }
        widgetReload = reload; DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: reload)
    }
    private func changedSelection() {
        controllerEpoch += 1; returnGeneration += 1
        controller?.stop(); controller = nil; controlsConnected = false
        returnPolicy = ReturnPolicy(); callActive = false; monitorRecoveryAttempts = 0
        settingsKnown = false; featureValues = [:]; pendingCommands.removeAll()
        idleClose?.cancel(); previousOutputWasBuds = false
        prefersBuds = false; lastBudsOutput = .distantPast
        batteryLeft = nil; batteryRight = nil; batteryCase = nil; batteryUpdated = nil
        noiseMode = -1; equalizer = -1; customEQAvailable = false
        customBands = [Double](repeating: 0, count: 9)
    }
}
