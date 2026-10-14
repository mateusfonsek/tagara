/// Decides push-to-talk transitions from raw key events.
///
/// Hold the trigger key and release to dictate. Tap it twice quickly to lock recording
/// hands-free; the next tap finishes and Esc cancels. Any other key pressed while holding
/// means the user is typing a shortcut, so the dictation is cancelled.
public struct HotkeyStateMachine: Sendable {
    public enum Input: Sendable { case triggerDown, triggerUp, otherKey, escape, tick }
    public enum Output: Sendable, Equatable { case press, release, cancel, lock }

    /// A press shorter than this counts as a tap, not a hold.
    public static let tapMaximum = 0.3
    /// Time allowed between the first tap's release and the second press.
    public static let doubleTapWindow = 0.35
    /// Hands-free recording finishes on its own after this long.
    public static let handsFreeLimit = 600.0

    public var handsFreeEnabled = true

    private enum State {
        case idle
        case holding(since: Double)
        case cancelled
        case awaitingSecondTap(until: Double)
        case lockingKeyDown(since: Double)
        case locked(since: Double)
        case finishing
    }

    private var state: State = .idle

    public init() {}

    /// When the owner should send `.tick`: the double-tap window closing or the hands-free limit.
    public var deadline: Double? {
        switch state {
        case .awaitingSecondTap(let until): until
        case .lockingKeyDown(let since), .locked(let since): since + Self.handsFreeLimit
        default: nil
        }
    }

    public mutating func handle(_ input: Input, at time: Double) -> Output? {
        switch (state, input) {
        case (.idle, .triggerDown):
            state = .holding(since: time)
            return .press

        case (.holding(let since), .triggerUp):
            if handsFreeEnabled && time - since < Self.tapMaximum {
                state = .awaitingSecondTap(until: time + Self.doubleTapWindow)
                return nil
            }
            state = .idle
            return .release
        case (.holding, .otherKey), (.holding, .escape):
            state = .cancelled
            return .cancel
        case (.cancelled, .triggerUp):
            state = .idle
            return nil

        case (.awaitingSecondTap(let until), .triggerDown):
            guard time <= until else {
                state = .holding(since: time)
                return .press
            }
            state = .lockingKeyDown(since: time)
            return .lock
        case (.awaitingSecondTap(let until), .tick):
            guard time > until else { return nil }
            state = .idle
            return .cancel
        case (.awaitingSecondTap, .otherKey), (.awaitingSecondTap, .escape):
            state = .idle
            return .cancel

        case (.lockingKeyDown(let since), .triggerUp):
            state = .locked(since: since)
            return nil
        case (.locked, .triggerDown):
            state = .finishing
            return .release
        case (.locked, .escape), (.lockingKeyDown, .escape):
            state = .idle
            return .cancel
        case (.locked(let since), .tick), (.lockingKeyDown(let since), .tick):
            guard time >= since + Self.handsFreeLimit else { return nil }
            state = .idle
            return .release
        case (.finishing, .triggerUp):
            state = .idle
            return nil

        default:
            return nil
        }
    }
}
