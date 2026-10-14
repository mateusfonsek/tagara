import AppKit
import SwiftUI
import TagaraCore

/// The main window: a native sidebar with Início, Histórico and Ajustes.
struct MainView: View {
    enum Page: String, Hashable { case inicio, historico, ajustes }

    @Environment(AppController.self) private var controller
    /// Reopens on the last tab, like other Mac apps.
    @AppStorage("selectedPage") private var page: Page = .inicio

    /// Permission changes happen in System Settings, so poll — but only while this window is open.
    private let refresh = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationSplitView {
            List(selection: Binding<Page?>(get: { page }, set: { if let new = $0 { page = new } })) {
                Label("Início", systemImage: "house").tag(Page.inicio)
                Label("Histórico", systemImage: "clock.arrow.circlepath").tag(Page.historico)
                Label("Ajustes", systemImage: "gearshape").tag(Page.ajustes)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
            .safeAreaInset(edge: .bottom) { SidebarStatus() }
        } detail: {
            switch page {
            case .inicio: HomeView(showHistory: { page = .historico })
            case .historico: HistoryView()
            case .ajustes: SettingsView()
            }
        }
        .tint(Brand.violeta)
        .frame(minWidth: 780, minHeight: 540)
        .onReceive(refresh) { _ in controller.refreshPermissions() }
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
        }
        .onDisappear { NSApp.setActivationPolicy(.accessory) }
    }
}

/// Live status at the foot of the sidebar, like a sync indicator in Mail.
private struct SidebarStatus: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.callout).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var color: Color {
        switch controller.phase {
        case .recording, .transcribing: Brand.violeta
        default: controller.isReady ? .green : .orange
        }
    }

    private var text: String {
        switch controller.phase {
        case .recording: "ouvindo…"
        case .transcribing: "escrevendo…"
        default: controller.isReady ? "Pronto" : "Falta configurar"
        }
    }
}

/// A key drawn like a keyboard keycap, for shortcuts in running text.
struct Keycap: View {
    let symbol: String
    let label: String

    init(symbol: String, label: String) {
        self.symbol = symbol
        self.label = label
    }

    init(_ key: TriggerKey) {
        self.init(symbol: key.symbol, label: key.side)
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(symbol).font(.system(size: 13, weight: .semibold))
            if !label.isEmpty {
                Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.background, in: .rect(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
        .shadow(color: .black.opacity(0.08), radius: 0, y: 1)
    }
}

/// The card surface used across the window: the system's quinary fill, no custom colors.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.quinary, in: .rect(cornerRadius: 12))
    }
}
