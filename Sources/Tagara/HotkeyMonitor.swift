import CoreGraphics
import TagaraCore
import Foundation

/// Listens for the right Option key system-wide via a listen-only event tap.
/// The tap is passive: the system only wakes us when a key event happens.
final class HotkeyMonitor {
    private static let rightOptionKeyCode: Int64 = 61
    /// NX_DEVICERALTKEYMASK — set while the right Option key is down.
    private static let rightOptionDeviceMask: UInt64 = 0x40
    private static let escapeKeyCode: Int64 = 53

    var onEvent: ((HotkeyStateMachine.Output) -> Void)?

    private var stateMachine = HotkeyStateMachine()
    private var pendingTick: DispatchWorkItem?

    var handsFreeEnabled: Bool {
        get { stateMachine.handsFreeEnabled }
        set { stateMachine.handsFreeEnabled = newValue }
    }
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var isRunning: Bool { tap != nil }

    /// Returns false when the system refuses the tap (Accessibility not granted).
    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        let mask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                monitor.handle(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        ) else { return false }

        self.tap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func handle(type: CGEventType, event: CGEvent) {
        let input: HotkeyStateMachine.Input
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        case .keyDown:
            input = event.getIntegerValueField(.keyboardEventKeycode) == Self.escapeKeyCode ? .escape : .otherKey
        case .flagsChanged:
            if event.getIntegerValueField(.keyboardEventKeycode) == Self.rightOptionKeyCode {
                let down = event.flags.rawValue & Self.rightOptionDeviceMask != 0
                input = down ? .triggerDown : .triggerUp
            } else {
                input = .otherKey
            }
        default:
            return
        }
        feed(input)
    }

    private func feed(_ input: HotkeyStateMachine.Input) {
        if let output = stateMachine.handle(input, at: ProcessInfo.processInfo.systemUptime) {
            onEvent?(output)
        }
        scheduleTick()
    }

    /// The state machine has no clock; wake it once at its next deadline (double-tap window
    /// or hands-free limit). Nothing is scheduled while idle.
    private func scheduleTick() {
        pendingTick?.cancel()
        pendingTick = nil
        guard let deadline = stateMachine.deadline else { return }
        let work = DispatchWorkItem { [weak self] in self?.feed(.tick) }
        pendingTick = work
        let delay = max(0, deadline - ProcessInfo.processInfo.systemUptime) + 0.01
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
