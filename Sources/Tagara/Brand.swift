import AppKit
import SwiftUI
import TagaraCore

/// Brand tokens from docs/brand-guidelines.md. The app sits on the system's own backgrounds;
/// the brand shows up as the violet accent and the graphite of the icon.
enum Brand {
    /// Accent for controls, selection and highlights. White text on it passes AA in both modes.
    static let violeta = Color(light: 0x5B2A86, dark: 0x8E5CC9)
    /// Lighter violet used on the always-dark recording pill.
    static let violetaClaro = Color(hex: 0xC7A2EC)
    /// The icon's background, also the recording pill.
    static let grafite = Color(hex: 0x2F332C)
    static let sobreGrafite = Color(hex: 0xF1F4EC)
}

extension Color {
    init(hex: UInt32) {
        self.init(nsColor: NSColor(hex: hex))
    }

    init(light: UInt32, dark: UInt32) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? NSColor(hex: dark) : NSColor(hex: light)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1)
    }
}

/// The three brand bars drawn as a menu bar template image (18 pt tall).
enum MenuBarGlyph {
    static func image(_ bars: VoiceBars, dimmed: Bool = false) -> NSImage {
        let size = NSSize(width: 16, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let width: CGFloat = 3.6, gap: CGFloat = 2.6
            let total = width * 3 + gap * 2
            var x = (rect.width - total) / 2
            NSColor.black.withAlphaComponent(dimmed ? 0.45 : 1).setFill()
            for height in [bars.left, bars.middle, bars.right] {
                let h = max(width, CGFloat(height) * 14)
                let bar = NSRect(x: x, y: (rect.height - h) / 2, width: width, height: h)
                NSBezierPath(roundedRect: bar, xRadius: width / 2, yRadius: width / 2).fill()
                x += width + gap
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
