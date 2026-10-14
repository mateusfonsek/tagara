import AppKit
import AVFoundation
import ApplicationServices

@MainActor
enum Permissions {
    static var microphone: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    static var accessibility: Bool { AXIsProcessTrusted() }

    static func requestMicrophone() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .audio)
        default:
            openSettings("Privacy_Microphone")
            return false
        }
    }

    /// Shows the system prompt that deep-links to Accessibility settings.
    static func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        if !AXIsProcessTrustedWithOptions([key: true] as CFDictionary) {
            openSettings("Privacy_Accessibility")
        }
    }

    private static func openSettings(_ pane: String) {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!
        NSWorkspace.shared.open(url)
    }
}
