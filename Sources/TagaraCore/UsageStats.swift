import Foundation

/// Aggregate counters only — the dictated text itself is never stored.
public struct UsageStats: Codable, Equatable, Sendable {
    public static let typingWordsPerMinute = 40.0
    /// Days of per-day word counts kept for the activity chart.
    public static let daysKept = 30

    public struct Day: Equatable, Sendable {
        public let date: Date
        public let words: Int
    }

    public private(set) var totalWords = 0
    public private(set) var dictations = 0
    public private(set) var spokenSeconds = 0.0
    /// Words per day, keyed "yyyy-m-d".
    private var daily: [String: Int] = [:]

    public init() {}

    public var secondsSaved: Double {
        max(0, Double(totalWords) / Self.typingWordsPerMinute * 60 - spokenSeconds)
    }

    var storedDays: Int { daily.count }

    public func wordsToday(at date: Date = .now) -> Int {
        daily[Self.dayKey(date)] ?? 0
    }

    /// The last `count` days, oldest first, including days with no dictation.
    public func lastDays(_ count: Int, endingAt end: Date = .now) -> [Day] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: end)
        return (0..<count).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            return Day(date: date, words: daily[Self.dayKey(date)] ?? 0)
        }
    }

    public mutating func record(text: String, spokenSeconds seconds: Double, at date: Date = .now) {
        let words = text.split(whereSeparator: \.isWhitespace).count
        daily[Self.dayKey(date), default: 0] += words
        totalWords += words
        dictations += 1
        spokenSeconds += seconds
        prune(before: date)
    }

    private mutating func prune(before date: Date) {
        let keep = Set(lastDays(Self.daysKept, endingAt: date).map { Self.dayKey($0.date) })
        daily = daily.filter { keep.contains($0.key) }
    }

    private static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }

    // Older saved stats only had totals; read them without failing.
    private enum CodingKeys: String, CodingKey { case totalWords, dictations, spokenSeconds, daily }
    private enum LegacyKeys: String, CodingKey { case todayKey, todayWords }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalWords = try c.decode(Int.self, forKey: .totalWords)
        dictations = try c.decode(Int.self, forKey: .dictations)
        spokenSeconds = try c.decode(Double.self, forKey: .spokenSeconds)
        daily = try c.decodeIfPresent([String: Int].self, forKey: .daily) ?? [:]
        let legacy = try decoder.container(keyedBy: LegacyKeys.self)
        if daily.isEmpty, let key = try legacy.decodeIfPresent(String.self, forKey: .todayKey), !key.isEmpty,
           let words = try legacy.decodeIfPresent(Int.self, forKey: .todayWords) {
            daily[key] = words
        }
    }
}
