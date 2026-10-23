// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import SwiftUI

struct BridgeView: View {
    @ObservedObject var model: BridgeModel
    private let accent = Color(red: 0.28, green: 0.40, blue: 0.92)
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Image(systemName: "headphones").font(.system(size: 31, weight: .medium))
                        .foregroundStyle(.white).frame(width: 62, height: 62)
                        .background(accent.gradient, in: RoundedRectangle(cornerRadius: 18))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("BudsBridge").font(.system(size: 28, weight: .bold))
                        Text("Mac ↔ Telefon").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("DENEYSEL").font(.system(size: 10, weight: .semibold)).padding(7)
                        .background(accent.opacity(0.1), in: Capsule()).foregroundStyle(accent)
                }
                HStack(spacing: 16) {
                    Label("Doğrudan Bluetooth", systemImage: "antenna.radiowaves.left.and.right")
                    Label("Telefon uygulaması gerektirmez", systemImage: "iphone")
                }.font(.caption).foregroundStyle(.secondary)
                HStack {
                    Label("Apple WidgetKit · Küçük", systemImage: "square.grid.2x2").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Widget’ı ekle") { NotificationCenter.default.post(name: .widgetHelp, object: nil) }.buttonStyle(.link)
                }
                VStack(alignment: .leading, spacing: 13) {
                    Label("Kulaklığın", systemImage: "earbuds").font(.headline)
                    if model.devices.isEmpty {
                        Text("Eşleşmiş Galaxy Buds henüz görünmüyor.").foregroundStyle(.secondary)
                    } else {
                        Picker("Cihaz", selection: $model.selectedID) {
                            ForEach(model.devices) { device in Text(device.name).tag(device.id) }
                        }.disabled(model.busy)
                        Label(model.selected?.connected == true ? "Mac’e bağlı" : "Mac’e bağlı değil",
                              systemImage: model.selected?.connected == true ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(model.selected?.connected == true ? Color.green : Color.secondary)
                        if model.selected?.supportedName == false {
                            Text("Bu sürümün protokol kontrolleri yalnızca Buds3 Pro için etkin. Cihaz adında Buds3 Pro bulunmalı.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Button("Mac’e bağlan") { model.connect() }.buttonStyle(.bordered)
                            .disabled(model.selected == nil || model.busy || model.preview)
                        Button("Bağlantıyı bırak") { model.release() }.buttonStyle(.bordered)
                            .disabled(model.selected?.connected != true || model.busy || model.preview)
                        Spacer()
                        if model.busy { ProgressView().controlSize(.small) }
                    }
                    HStack {
                        Button("Bluetooth izni / yenile") { model.requestBluetooth() }
                        Button("Bluetooth ayarları") { model.bluetoothSettings() }
                    }.buttonStyle(.link).disabled(model.preview)
                    if !model.outputName.isEmpty {
                        Text("Ses çıkışı: \(model.outputName)").font(.caption).foregroundStyle(.secondary)
                    }
                }.card()
                VStack(alignment: .leading, spacing: 13) {
                    Label("Çoklu bağlantıyı dene", systemImage: "point.3.connected.trianglepath.dotted").font(.headline)
                    Text("Samsung’un cihaz geçiş bilgisini kulaklığın geçici belleğinde etkinleştirmeyi dener.")
                        .font(.callout).foregroundStyle(.secondary)
                    Button("Etkinleştir ve cevabı kontrol et") { model.apply() }
                        .buttonStyle(.borderedProminent).disabled(!model.canApply)
                    Text(model.protocolStatus).font(.callout.weight(.semibold)).textSelection(.enabled)
                    Text(model.message).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Toggle("Arama bitince Mac’in ses çıkışını Buds’a al", isOn: Binding(get: { model.returnToMac }, set: { model.setReturnToMac($0) }))
                    Divider()
                    Toggle(isOn: Binding(get: { model.automatic }, set: { model.setAutomatic($0) })) {
                        Text("Her Mac bağlantısında otomatik uygula")
                    }.toggleStyle(.switch).disabled(model.busy || model.preview)
                    Text("Kutuda kapanınca ayar sıfırlanabilir. Sürekli tarama ve arka planda sorgulama yapılmaz.")
                        .font(.caption).foregroundStyle(.secondary)
                }.card()
                if model.selected?.supportedName == true { BudsControlsView(model: model).card() }
                VStack(alignment: .leading, spacing: 7) {
                    Label("Deneysel · Buds3 Pro", systemImage: "info.circle").font(.callout.weight(.medium))
                    Text("Arama geçişi ve Mac’e ses dönüşü bir Buds3 Pro + Galaxy S25+ kurulumunda denendi. Diğer telefon ve yazılım sürümleri ayrıca test edilmeli; iPhone’da otomatik geçiş henüz doğrulanmadı.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Geri almak için otomatik uygulamayı kapatıp kulaklıkları kutuda kapat ve yeniden aç.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                DisclosureGroup("İşlem günlüğü") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(model.log.isEmpty ? "Henüz işlem yok." : model.log.joined(separator: "\n"))
                            .font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Günlüğü kopyala") { model.copyLog() }
                    }.padding(.top, 8)
                }
                Text("Wi-Fi bağlantısı ve telefon tarafında ek servis gerektirmez.")
                    .font(.system(size: 11)).foregroundStyle(.tertiary)
                Text("GPL-3.0 · Garanti verilmez. Bağımsız bir projedir; Samsung veya Apple tarafından desteklenmez.")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }.padding(26)
        }.background(Color(nsColor: .windowBackgroundColor)).frame(minWidth: 540, minHeight: 700).tint(accent)
    }
}

private extension View {
    func card() -> some View {
        self.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
