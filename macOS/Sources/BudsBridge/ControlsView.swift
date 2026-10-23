// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import SwiftUI

struct BudsControlsView: View {
    @ObservedObject var model: BridgeModel
    private let features: [(String, String)] = [
        ("voice", "Konuşmayı algıla"), ("siren", "Siren algılama"),
        ("onebud", "Tek kulaklıkla gürültü kontrolü"), ("sidetone", "Aramalarda kendi sesimi duy"),
        ("clearcall", "Daha net arama sesi"), ("autopause", "Kulaklık çıkarılınca duraklat"),
        ("adaptivevolume", "Uyarlanabilir ses yüksekliği"), ("seamless", "Kesintisiz kulaklık bağlantısı")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Kulaklık kontrolleri", systemImage: "slider.horizontal.3").font(.headline)
                Spacer()
                Circle().fill(model.controlsConnected ? Color.green : Color.secondary).frame(width: 7, height: 7)
            }
            BatteryRow(model: model)
            if !model.controlsConnected {
                Text("Canlı ayarlar için kulaklığın kontrol kanalı açılmalı.").font(.caption).foregroundStyle(.secondary)
                Button("Kontrol kanalını bağla") { model.startControls() }.disabled(model.selected?.connected != true || model.busy)
            }
            Text("Gürültü kontrolü").font(.caption.weight(.medium))
            Picker("Gürültü kontrolü", selection: Binding(get: { model.noiseMode }, set: { model.setNoise($0) })) {
                Text("—").tag(-1); Text("Kapalı").tag(0); Text("ANC").tag(1)
                Text("Ortam").tag(2); Text("Uyarlanır").tag(3)
            }.pickerStyle(.segmented).labelsHidden().disabled(model.selected?.connected != true || model.busy)
            Picker("Ekolayzır", selection: Binding(get: { model.equalizer }, set: { model.setEQ($0) })) {
                Text("Bilinmiyor").tag(-1); Text("Normal").tag(0); Text("Bas artırma").tag(1)
                Text("Yumuşak").tag(2); Text("Dinamik").tag(3); Text("Net").tag(4)
                Text("Tiz artırma").tag(5)
                if model.customEQAvailable { Text("Özel · 9 bant").tag(6) }
            }.disabled(model.selected?.connected != true || model.busy)
            DisclosureGroup("9 bant özel ekolayzır") {
                VStack(alignment: .leading, spacing: 8) {
                    if model.customEQAvailable {
                        ForEach(0..<9, id: \.self) { index in
                            HStack {
                                Text(["63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"][index] + " Hz")
                                    .font(.caption.monospacedDigit()).frame(width: 46, alignment: .leading)
                                Slider(value: $model.customBands[index], in: -10...10, step: 1)
                                Text("\(Int(model.customBands[index]))").font(.caption.monospacedDigit()).frame(width: 25)
                            }
                        }
                        Button("Özel EQ’yu uygula") { model.applyCustomEQ() }
                    } else {
                        Text("Kulaklıktan bant desteğini ve mevcut değerleri oku.").font(.caption).foregroundStyle(.secondary)
                        Button("EQ verisini oku") { model.readCustomEQ() }
                    }
                }.padding(.top, 8).disabled(model.selected?.connected != true || model.busy)
            }
            DisclosureGroup("Konuşma, arama ve algılama") {
                VStack(alignment: .leading, spacing: 8) {
                    if !model.settingsKnown { Text("Kulaklık ayarları henüz gelmedi.").font(.caption).foregroundStyle(.secondary) }
                    ForEach(features, id: \.0) { key, title in
                        if let value = model.featureValues[key] {
                            Toggle(title, isOn: Binding(get: { model.featureValues[key] ?? value }, set: { model.setFeature(key, $0) }))
                        }
                    }
                }.padding(.top, 8).disabled(!model.controlsConnected)
            }
            DisclosureGroup("Dokunma ve sıkıştırma kontrolleri") {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(0..<7, id: \.self) { index in
                        Toggle(["Kontroller açık", "Tek dokunma", "Çift dokunma", "Üçlü dokunma", "Basılı tutma",
                                "Aramada çift dokunma", "Aramada basılı tutma"][index],
                            isOn: Binding(get: { model.touchEnabled[index] }, set: { model.setTouch(index, $0) }))
                    }
                }.padding(.top, 8).disabled(!model.settingsKnown || !model.controlsConnected)
            }
            Text(model.controlMessage).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Text("SSC/UHQ, 360 Ses ve canlı çeviri gibi Galaxy telefonuna bağlı ses işleme özellikleri Mac’e eklenmez.")
                .font(.caption2).foregroundStyle(.tertiary)
        }
    }
}

struct BatteryRow: View {
    @ObservedObject var model: BridgeModel
    var body: some View {
        HStack(spacing: 9) {
            battery("Sol", model.batteryLeft, "earbuds")
            battery("Sağ", model.batteryRight, "earbuds")
            battery("Kutu", model.batteryCase, "case")
        }
    }
    private func battery(_ title: String, _ value: Int?, _ symbol: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
            Text(title).foregroundStyle(.secondary)
            Text(value.map { "\($0)%" } ?? "—").fontWeight(.semibold).monospacedDigit()
        }.font(.caption).padding(9).frame(maxWidth: .infinity)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
    }
}

extension Notification.Name {
    static let openBridgeWindow = Notification.Name("BudsBridge.openWindow")
    static let widgetHelp = Notification.Name("BudsBridge.widgetHelp")
}
