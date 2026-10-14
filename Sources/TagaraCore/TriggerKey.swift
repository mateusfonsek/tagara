/// A raw keyboard event, as the event tap sees it.
public struct KeyEvent: Sendable {
    public enum Kind: Sendable { case flagsChanged, keyDown, keyUp }

    public let kind: Kind
    public let keyCode: Int64
    /// CGEventFlags raw value (flagsChanged only).
    public let flags: UInt64
    /// Auto-repeat while a key is held (keyDown only).
    public let isRepeat: Bool

    public init(kind: Kind, keyCode: Int64, flags: UInt64 = 0, isRepeat: Bool = false) {
        self.kind = kind
        self.keyCode = keyCode
        self.flags = flags
        self.isRepeat = isRepeat
    }
}

/// The key held to dictate. Modifiers report through flagsChanged with a device-specific flag
/// (so right ⌘ isn't confused with left ⌘); F13–F15 are ordinary keys with keyDown/keyUp.
public enum TriggerKey: String, CaseIterable, Sendable, Identifiable {
    case rightOption, rightCommand, rightControl, fn, f13, f14, f15

    public static let `default` = TriggerKey.rightOption
    private static let escapeKeyCode: Int64 = 53

    public var id: String { rawValue }

    /// Symbol for keycaps and short phrases ("toque no ⌥").
    public var symbol: String {
        switch self {
        case .rightOption: "⌥"
        case .rightCommand: "⌘"
        case .rightControl: "⌃"
        case .fn: "fn"
        case .f13: "F13"
        case .f14: "F14"
        case .f15: "F15"
        }
    }

    /// The word under the symbol on a keycap ("direito"), empty when the symbol says it all.
    public var side: String {
        switch self {
        case .rightOption, .rightCommand, .rightControl: "direito"
        case .fn: "🌐"
        case .f13, .f14, .f15: ""
        }
    }

    /// Full name for pickers and sentences ("⌥ direito").
    public var name: String {
        side.isEmpty ? symbol : "\(symbol) \(side)"
    }

    private var keyCode: Int64 {
        switch self {
        case .rightOption: 61
        case .rightCommand: 54
        case .rightControl: 62
        case .fn: 63
        case .f13: 105
        case .f14: 107
        case .f15: 113
        }
    }

    /// The flag that is set while this modifier is down; nil for ordinary keys.
    private var modifierFlag: UInt64? {
        switch self {
        case .rightOption: 0x40 // NX_DEVICERALTKEYMASK
        case .rightCommand: 0x10 // NX_DEVICERCMDKEYMASK
        case .rightControl: 0x2000 // NX_DEVICERCTLKEYMASK
        case .fn: 0x800000 // kCGEventFlagMaskSecondaryFn
        case .f13, .f14, .f15: nil
        }
    }

    /// What the state machine should hear for this event, or nil to ignore it.
    public func input(for event: KeyEvent) -> HotkeyStateMachine.Input? {
        if event.kind == .keyDown && event.keyCode == Self.escapeKeyCode { return .escape }
        if let flag = modifierFlag {
            switch event.kind {
            case .flagsChanged:
                guard event.keyCode == keyCode else { return .otherKey }
                return event.flags & flag != 0 ? .triggerDown : .triggerUp
            case .keyDown: return .otherKey
            case .keyUp: return nil
            }
        }
        switch event.kind {
        case .flagsChanged: return .otherKey
        case .keyDown:
            guard event.keyCode == keyCode else { return .otherKey }
            return event.isRepeat ? nil : .triggerDown
        case .keyUp:
            return event.keyCode == keyCode ? .triggerUp : nil
        }
    }
}
