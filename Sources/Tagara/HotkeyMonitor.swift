import CoreGraphics
import TagaraCore
import Foundation

/// Listens for the dictation key system-wide via a listen-only event tap.
/// The tap is passive: the system only wakes us when a key event happens.
final class HotkeyMonitor {
    var onEvent: ((HotkeyStateMachine.Output) -> Void)?

    /// Changing the key drops any half-finished press or tap on the old one.
    var trigger = TriggerKey.default {
        didSet {
            guard trigger != oldValue else { return }
            let handsFree = stateMachine.handsFreeEnabled
            stateMachine = HotkeyStateMachine()
            stateMachine.handsFreeEnabled = handsFree
            pendingTick?.cancel()
            pendingTick = nil
        }
    }

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
            | (1 << CGEventType.keyUp.rawValue)
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
        let kind: KeyEvent.Kind
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        case .keyDown: kind = .keyDown
        case .keyUp: kind = .keyUp
        case .flagsChanged: kind = .flagsChanged
        default: return
        }
        let key = KeyEvent(
            kind: kind,
            keyCode: event.getIntegerValueField(.keyboardEventKeycode),
            flags: event.flags.rawValue,
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0)
        if let input = trigger.input(for: key) { feed(input) }
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
