import AppKit
import Carbon.HIToolbox

/// Types text into whatever field has focus by pasting it, then restores the clipboard.
/// Pasting (instead of synthesizing each keystroke) keeps accents intact and is instant
/// in terminals, Electron apps and browsers alike.
@MainActor
enum TextInserter {
    /// Tells clipboard managers to ignore our temporary entry (nspasteboard.org convention).
    private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    static func insert(_ text: String) {
        let pasteboard = NSPasteboard.general
        let saved = snapshot(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        pasteboard.setData(Data(), forType: transientType)
        let ourChange = pasteboard.changeCount

        postCommandV()

        // Give the target app time to read the pasteboard before restoring it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard pasteboard.changeCount == ourChange else { return }
            pasteboard.clearContents()
            if !saved.isEmpty { pasteboard.writeObjects(saved) }
        }
    }

    private static func snapshot(_ pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy
        }
    }

    private static func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let v = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
