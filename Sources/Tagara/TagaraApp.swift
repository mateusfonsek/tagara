import AppKit
import SwiftUI
import TagaraCore

@main
struct TagaraApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate
    @State private var controller = AppController.shared

    var body: some Scene {
        MenuBarExtra {
            MenuContent().environment(controller)
        } label: {
            MenuBarLabel().environment(controller)
        }

        Window("Tagara", id: "main") {
            MainView().environment(controller)
        }
        .defaultSize(width: 960, height: 760)
        .windowResizability(.contentMinSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        MainActor.assumeIsolated { AppController.shared.openMainWindow?() }
        return true
    }
}

/// The menu bar icon. It also hands the window opener to the controller, since
/// only views can reach `openWindow`, and this one exists from launch.
private struct MenuBarLabel: View {
    @Environment(AppController.self) private var controller
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(nsImage: glyph)
            .onAppear {
                controller.openMainWindow = {
                    openWindow(id: "main")
                    NSApp.activate()
                }
                controller.start()
            }
    }

    /// The brand bars: still at rest, live with your voice while recording, flat while transcribing.
    private var glyph: NSImage {
        switch controller.phase {
        case .recording: MenuBarGlyph.image(VoiceBars(level: Double(controller.level)))
        case .transcribing: MenuBarGlyph.image(VoiceBars(left: 0.48, middle: 0.48, right: 0.48))
        case .notice: MenuBarGlyph.image(.resting, dimmed: true)
        case .idle: MenuBarGlyph.image(.resting, dimmed: !controller.isReady)
        }
    }
}

private struct MenuContent: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        Text(controller.isReady ? "Pronto. Segura \(controller.triggerKey.name) e fala." : "Falta configurar")
        Divider()
        if let version = controller.updater.availableVersion {
            Button("Atualizar para \(version)…") { controller.updater.install() }
            Divider()
        }
        MicrophonePicker().pickerStyle(.menu)
        Divider()
        Button("Copiar último ditado") { controller.copyLastTranscript() }
            .disabled(controller.lastTranscript == nil && controller.history.entries.isEmpty)
        Button("Abrir Tagara…") { controller.openMainWindow?() }
            .keyboardShortcut(",")
        Divider()
        Button("Sair") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
