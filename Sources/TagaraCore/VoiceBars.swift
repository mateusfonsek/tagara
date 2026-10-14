/// Heights (0...1) of the three brand bars: the app icon, the menu bar glyph and the recording pill.
public struct VoiceBars: Equatable, Sendable {
    public let left: Double
    public let middle: Double
    public let right: Double

    /// The icon's own proportions, used whenever nothing is being recorded.
    public static let resting = VoiceBars(left: 0.48, middle: 1, right: 0.48)

    public init(left: Double, middle: Double, right: Double) {
        self.left = left
        self.middle = middle
        self.right = right
    }

    /// Bars driven by the live microphone level (0...1). Sides react less than the middle
    /// and slightly differently from each other, so it reads as a voice rather than a meter.
    public init(level: Double) {
        let l = min(max(level, 0), 1)
        self.init(left: 0.25 + 0.55 * l, middle: 0.35 + 0.65 * l, right: 0.25 + 0.45 * l)
    }
}
