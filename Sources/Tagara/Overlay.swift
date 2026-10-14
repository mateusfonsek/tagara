import AppKit
import TagaraCore
import SwiftUI

/// Small floating pill near the bottom of the screen. It never takes focus,
/// so the app you are dictating into stays the key window.
@MainActor
final class OverlayController {
    private let panel: NSPanel

    init(controller: AppController) {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = NSHostingView(rootView: OverlayView().environment(controller))
    }

    func show() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            let size = panel.frame.size
            panel.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.minY + 24))
        }
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}

private struct OverlayView: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        HStack(spacing: 10) {
            switch controller.phase {
            case .recording:
                PillBars(bars: VoiceBars(level: Double(controller.level)))
                Text(controller.handsFree ? "ouvindo… toque ⌥ para terminar" : "ouvindo…")
                    .foregroundStyle(Brand.sobreGrafite.opacity(0.85))
            case .transcribing:
                ThinkingBars()
                Text("escrevendo…").foregroundStyle(Brand.sobreGrafite.opacity(0.85))
            case .notice(let message):
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Brand.violetaClaro)
                Text(message).foregroundStyle(Brand.sobreGrafite.opacity(0.92)).lineLimit(1)
            case .idle:
                EmptyView()
            }
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(Capsule().fill(Brand.grafite.opacity(0.94)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.1)))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.snappy(duration: 0.2), value: controller.phase)
    }
}

/// The icon's three bars, live: sides in paper white, the middle one in carimbo.
private struct PillBars: View {
    let bars: VoiceBars

    var body: some View {
        HStack(spacing: 3) {
            bar(bars.left, Brand.sobreGrafite)
            bar(bars.middle, Brand.violetaClaro)
            bar(bars.right, Brand.sobreGrafite)
        }
        .frame(height: 24)
        .animation(.easeOut(duration: 0.08), value: bars)
    }

    private func bar(_ height: Double, _ color: Color) -> some View {
        Capsule().fill(color).frame(width: 4.5, height: max(8, 24 * height))
    }
}

/// While transcribing, the bars breathe in sequence instead of following the mic.
private struct ThinkingBars: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate * 5
            let wave = { (offset: Double) in 0.45 + 0.35 * (0.5 + 0.5 * sin(t - offset)) }
            PillBars(bars: VoiceBars(left: wave(0), middle: wave(0.9), right: wave(1.8)))
        }
    }
}
