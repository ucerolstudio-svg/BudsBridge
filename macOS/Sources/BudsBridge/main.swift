// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import AppKit
import SwiftUI
import BridgeCore
import CoreBluetooth

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var item: NSStatusItem!
    private var window: NSWindow!
    private var model: BridgeModel!
    private var hardwareTimer: Timer?
    func applicationDidFinishLaunching(_ notification: Notification) {
        model = BridgeModel(preview: CommandLine.arguments.contains("--preview"))
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "headphones", accessibilityDescription: "BudsBridge")
        let menu = NSMenu(); menu.delegate = self; menu.autoenablesItems = false; item.menu = menu
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 580, height: 830),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = model.preview ? "BudsBridge — Önizleme" : "BudsBridge"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: BridgeView(model: model))
        window.center(); show()
        NotificationCenter.default.addObserver(self, selector: #selector(show), name: .openBridgeWindow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(widgetHelp), name: .widgetHelp, object: nil)
        if CommandLine.arguments.contains("--hardware-test") {
            model.requestBluetooth()
            var connectionAttempted = false
            var ticks = 0
            hardwareTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                ticks += 1
                guard ticks < 120 else { timer.invalidate(); self.model.addLog("Bluetooth izni / cihaz bekleme süresi doldu."); return }
                guard CBManager.authorization == .allowedAlways else { return }
                self.model.refresh()
                guard let selected = self.model.selected, !self.model.busy else { return }
                if selected.connected {
                    timer.invalidate(); self.model.addLog("Donanım denemesi başladı."); self.model.apply()
                } else if !connectionAttempted {
                    connectionAttempted = true; self.model.addLog("Kulaklığa Mac bağlantısı deneniyor."); self.model.connect()
                } else {
                    timer.invalidate(); self.model.addLog("Mac bağlantısı kurulamadı. Bluetooth ayarlarından bağlantı gerekli.")
                }
            }
        }
    }
    @objc func show() { model.refresh(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc func connect() { model.connect() }
    @objc func apply() { model.apply() }
    @objc func disconnectFromMac() { model.release() }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func legal() {
        if let url = Bundle.main.url(forResource: "LEGAL", withExtension: "md") { NSWorkspace.shared.open(url) }
    }
    @objc func widgetHelp() {
        let alert = NSAlert()
        alert.messageText = "Küçük Apple widget’ını ekle"
        alert.informativeText = "Masaüstünde boş bir yere sağ tıkla → Widget’ları Düzenle. Galeride BudsBridge / Buds3 Pro’yu ara ve küçük widget’ı ekle. Widget’a dokunmak Mac’in sesini Buds’a alır."
        alert.addButton(withTitle: "Tamam"); alert.runModal()
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "budsbridge" {
            show()
            if url.host == "listen" { model.restoreOutput() }
        }
    }
    func menuWillOpen(_ menu: NSMenu) {
        model.refresh(); menu.removeAllItems()
        let title = NSMenuItem(title: "BudsBridge · \(model.protocolStatus)", action: nil, keyEquivalent: "")
        title.isEnabled = false; menu.addItem(title)
        menu.addItem(.separator())
        add(menu, "BudsBridge’i aç", #selector(show), "")
        add(menu, "Apple widget’ını ekleme adımları", #selector(widgetHelp), "")
        add(menu, "Lisans, garanti ve yasal bilgiler", #selector(legal), "")
        add(menu, "Mac’e bağlan", #selector(connect), "m", enabled: model.selected != nil && !model.busy && !model.preview)
        add(menu, "Çoklu bağlantıyı etkinleştirmeyi dene", #selector(apply), "e", enabled: model.canApply)
        add(menu, "Mac bağlantısını bırak", #selector(disconnectFromMac), "b", enabled: model.selected?.connected == true && !model.busy && !model.preview)
        menu.addItem(.separator()); add(menu, "Çıkış", #selector(quit), "q")
    }
    private func add(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String, enabled: Bool = true) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key); item.target = self
        item.isEnabled = enabled; menu.addItem(item)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
let delegate = AppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
