/// Decides push-to-talk transitions from raw key events.
///
/// The trigger key held alone starts a dictation. Any other key pressed while it is
/// held means the user is typing a shortcut, so the dictation is cancelled.
public struct HotkeyStateMachine: Sendable {
    public enum Input: Sendable { case triggerDown, triggerUp, otherKey }
    public enum Output: Sendable, Equatable { case press, release, cancel }

    private enum State { case idle, holding, cancelled }
    private var state: State = .idle

    public init() {}

    public mutating func handle(_ input: Input) -> Output? {
        switch (state, input) {
        case (.idle, .triggerDown):
            state = .holding
            return .press
        case (.holding, .triggerUp):
            state = .idle
            return .release
        case (.holding, .otherKey):
            state = .cancelled
            return .cancel
        case (.cancelled, .triggerUp):
            state = .idle
            return nil
        default:
            return nil
        }
    }
}
