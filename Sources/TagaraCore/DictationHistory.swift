import Foundation

/// The most recent dictations, newest first, capped at `limit`.
public struct DictationHistory: Codable, Equatable, Sendable {
    public struct Entry: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let text: String
        public let date: Date
        /// The app that had focus when the text was pasted.
        public let app: String?
    }

    public private(set) var entries: [Entry] = []
    public let limit: Int

    public init(limit: Int = 50) {
        self.limit = limit
    }

    public mutating func add(text: String, app: String?, at date: Date = .now) {
        entries.insert(Entry(id: UUID(), text: text, date: date, app: app), at: 0)
        if entries.count > limit { entries.removeLast(entries.count - limit) }
    }

    public mutating func remove(id: UUID) {
        entries.removeAll { $0.id == id }
    }

    public mutating func clear() {
        entries.removeAll()
    }
}
