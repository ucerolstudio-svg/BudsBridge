// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 BudsBridge contributors.
// Distributed without warranty; see LICENSE and LEGAL.md.

import WidgetKit
import SwiftUI
import Foundation
import BridgeCore
import os

private let widgetKind = "BudsBridgeSmall"

struct BudsEntry: TimelineEntry {
    var date: Date
    var snapshot: BudsWidgetSnapshot
}

struct BudsProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudsEntry { BudsEntry(date: Date(), snapshot: .init()) }
    func getSnapshot(in context: Context, completion: @escaping (BudsEntry) -> Void) { completion(read()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BudsEntry>) -> Void) {
        // The host app requests a reload only when a meaningful cached value changes.
        // The extension never opens Bluetooth, starts a timer, or polls the app.
        completion(Timeline(entries: [read()], policy: .never))
    }
    private func read() -> BudsEntry {
        CFPreferencesAppSynchronize("dev.budsbridge.mac" as CFString)
        let data = CFPreferencesCopyAppValue("widget-snapshot" as CFString, "dev.budsbridge.mac" as CFString) as? Data
        let snapshot = data.flatMap { try? JSONDecoder().decode(BudsWidgetSnapshot.self, from: $0) } ?? .init()
        Logger(subsystem: "dev.budsbridge.mac.widget", category: "snapshot").info("Widget snapshot loaded: \(data != nil)")
        return BudsEntry(date: Date(), snapshot: snapshot)
    }
}

struct BudsSmallWidgetView: View {
    var entry: BudsEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "headphones").font(.system(size: 14, weight: .semibold)).foregroundStyle(.indigo)
                Text("Buds3 Pro").font(.system(size: 12, weight: .semibold))
                Spacer(minLength: 0)
                Circle().fill(entry.snapshot.connected ? .green : .secondary).frame(width: 5, height: 5)
            }
            HStack(spacing: 8) {
                battery("Sol", value: entry.snapshot.left)
                battery("Sağ", value: entry.snapshot.right)
            }.frame(maxWidth: .infinity)
            HStack(spacing: 4) {
                Image(systemName: "case")
                Text(entry.snapshot.cradle.map { "\($0)%" } ?? "—")
                Spacer()
                Text(entry.snapshot.inCall ? "Arama" : modeName).lineLimit(1)
            }.font(.system(size: 10)).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Image(systemName: "laptopcomputer")
                Text("Mac’te dinle")
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 8, weight: .semibold))
            }.font(.system(size: 10, weight: .medium)).foregroundStyle(.indigo)
            HStack(spacing: 3) {
                Text("Son veri:")
                if let updated = entry.snapshot.updated { Text(updated, style: .time) }
                else { Text("bekleniyor") }
            }.font(.system(size: 8)).foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) { Color.indigo.opacity(0.07) }
        .widgetURL(URL(string: "budsbridge://listen"))
        .accessibilityLabel("Buds3 Pro: sol \(entry.snapshot.left.map(String.init) ?? "bilinmiyor"), sağ \(entry.snapshot.right.map(String.init) ?? "bilinmiyor") yüzde. Mac’te dinlemek için aç.")
    }
    private var modeName: String {
        [0: "Kapalı", 1: "ANC", 2: "Ortam", 3: "Adaptif"][entry.snapshot.noiseMode] ?? "BudsBridge"
    }
    private func battery(_ title: String, value: Int?) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().stroke(Color.primary.opacity(0.08), lineWidth: 3)
                Circle().trim(from: 0, to: CGFloat(value ?? 0) / 100)
                    .stroke(Color.indigo.gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round)).rotationEffect(.degrees(-90))
                Text(value.map { "\($0)" } ?? "—").font(.system(size: 18, weight: .semibold, design: .rounded)).minimumScaleFactor(0.8)
            }.frame(width: 40, height: 40)
            Text(title).font(.system(size: 9)).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }
}

@main
struct BudsBridgeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: BudsProvider()) { entry in BudsSmallWidgetView(entry: entry) }
            .configurationDisplayName("Buds3 Pro")
            .description("BudsBridge’in son aldığı pil ve mod bilgilerini gösterir. Mac’te dinlemek için dokun. Uygulama açık olmalı.")
            .supportedFamilies([.systemSmall])
    }
}
