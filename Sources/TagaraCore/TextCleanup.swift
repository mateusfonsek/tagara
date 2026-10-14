public enum TextCleanup {
    /// Trims the transcript and collapses runs of whitespace into single spaces.
    public static func clean(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
