/// Where a finished dictation goes. Text is pasted only into the app that was in front when
/// recording began; if another app took focus meanwhile (easy in hands-free mode), pasting
/// would type into the wrong window, so the text is left on the clipboard instead.
public enum PasteTarget: Equatable, Sendable {
    case paste
    case copyOnly

    /// Process IDs of the frontmost app when recording started and now.
    public static func decide(startedIn start: Int32?, frontmostNow now: Int32?) -> PasteTarget {
        guard let start else { return .paste }
        return start == now ? .paste : .copyOnly
    }
}
