import Foundation
import Testing
@testable import TagaraCore

@Suite struct HotkeyStateMachineTests {
    @Test func pressThenReleaseEmitsPressAndRelease() {
        var sm = HotkeyStateMachine()
        #expect(sm.handle(.triggerDown) == .press)
        #expect(sm.handle(.triggerUp) == .release)
    }

    @Test func otherKeyWhileHoldingCancels() {
        var sm = HotkeyStateMachine()
        _ = sm.handle(.triggerDown)
        #expect(sm.handle(.otherKey) == .cancel)
        #expect(sm.handle(.triggerUp) == nil)
    }

    @Test func otherKeyWhenIdleIsIgnored() {
        var sm = HotkeyStateMachine()
        #expect(sm.handle(.otherKey) == nil)
        #expect(sm.handle(.triggerUp) == nil)
    }

    @Test func repeatedDownDoesNotPressTwice() {
        var sm = HotkeyStateMachine()
        _ = sm.handle(.triggerDown)
        #expect(sm.handle(.triggerDown) == nil)
    }

    @Test func worksAgainAfterCancel() {
        var sm = HotkeyStateMachine()
        _ = sm.handle(.triggerDown)
        _ = sm.handle(.otherKey)
        _ = sm.handle(.triggerUp)
        #expect(sm.handle(.triggerDown) == .press)
    }
}

@Suite struct TextCleanupTests {
    @Test func trimsAndCollapsesWhitespace() {
        #expect(TextCleanup.clean("  olá   mundo \n") == "olá mundo")
    }

    @Test func emptyStaysEmpty() {
        #expect(TextCleanup.clean("   ") == "")
    }
}

@Suite struct UsageStatsTests {
    let day1 = Date(timeIntervalSince1970: 1_760_000_000)

    @Test func countsWordsAndSpeech() {
        var stats = UsageStats()
        stats.record(text: "faz o deploy agora", spokenSeconds: 2, at: day1)
        #expect(stats.totalWords == 4)
        #expect(stats.wordsToday(at: day1) == 4)
        #expect(stats.dictations == 1)
    }

    @Test func todayResetsOnNewDay() {
        var stats = UsageStats()
        stats.record(text: "um dois", spokenSeconds: 1, at: day1)
        let nextDay = day1.addingTimeInterval(86_400)
        #expect(stats.wordsToday(at: nextDay) == 0)
        stats.record(text: "três", spokenSeconds: 1, at: nextDay)
        #expect(stats.wordsToday(at: nextDay) == 1)
        #expect(stats.totalWords == 3)
    }

    @Test func timeSavedComparesWithTypingAt40wpm() {
        var stats = UsageStats()
        // 80 words typed at 40 wpm = 120 s; spoken in 30 s → saved 90 s
        stats.record(text: Array(repeating: "x", count: 80).joined(separator: " "), spokenSeconds: 30, at: day1)
        #expect(stats.secondsSaved == 90)
    }

    @Test func roundTripsThroughCodable() throws {
        var stats = UsageStats()
        stats.record(text: "a b c", spokenSeconds: 1, at: day1)
        let decoded = try JSONDecoder().decode(UsageStats.self, from: JSONEncoder().encode(stats))
        #expect(decoded == stats)
    }
}

@Suite struct DictationHistoryTests {
    @Test func newestFirst() {
        var history = DictationHistory()
        history.add(text: "primeiro", app: "Slack")
        history.add(text: "segundo", app: "Terminal")
        #expect(history.entries.map(\.text) == ["segundo", "primeiro"])
        #expect(history.entries.first?.app == "Terminal")
    }

    @Test func keepsOnlyTheLimit() {
        var history = DictationHistory(limit: 3)
        for i in 1...5 { history.add(text: "\(i)", app: nil) }
        #expect(history.entries.map(\.text) == ["5", "4", "3"])
    }

    @Test func removesById() {
        var history = DictationHistory()
        history.add(text: "a", app: nil)
        history.add(text: "b", app: nil)
        history.remove(id: history.entries[0].id)
        #expect(history.entries.map(\.text) == ["a"])
    }

    @Test func clearEmpties() {
        var history = DictationHistory()
        history.add(text: "a", app: nil)
        history.clear()
        #expect(history.entries.isEmpty)
    }

    @Test func roundTripsThroughCodable() throws {
        var history = DictationHistory()
        history.add(text: "olá", app: "WhatsApp")
        let decoded = try JSONDecoder().decode(DictationHistory.self, from: JSONEncoder().encode(history))
        #expect(decoded == history)
    }
}

@Suite struct VoiceBarsTests {
    @Test func restingShapeMatchesTheIcon() {
        let bars = VoiceBars.resting
        #expect(bars.middle == 1)
        #expect(bars.left == bars.right)
        #expect(bars.left < bars.middle)
    }

    @Test func silenceKeepsBarsShortButVisible() {
        let bars = VoiceBars(level: 0)
        #expect(bars.middle > 0)
        #expect(bars.middle < VoiceBars.resting.middle)
    }

    @Test func louderVoiceMeansTallerBars() {
        let quiet = VoiceBars(level: 0.2), loud = VoiceBars(level: 0.9)
        #expect(loud.middle > quiet.middle)
        #expect(loud.left > quiet.left)
    }

    @Test func heightsStayWithinOne() {
        let bars = VoiceBars(level: 5)
        #expect([bars.left, bars.middle, bars.right].allSatisfy { $0 <= 1 })
    }
}

@Suite struct DailyWordsTests {
    let day1 = Date(timeIntervalSince1970: 1_760_000_000)

    @Test func lastDaysListsOldestFirstWithZerosForQuietDays() {
        var stats = UsageStats()
        stats.record(text: "um dois três", spokenSeconds: 1, at: day1)
        let twoDaysLater = day1.addingTimeInterval(2 * 86_400)
        stats.record(text: "quatro", spokenSeconds: 1, at: twoDaysLater)
        let days = stats.lastDays(3, endingAt: twoDaysLater)
        #expect(days.map(\.words) == [3, 0, 1])
    }

    @Test func keepsOnlyRecentDays() {
        var stats = UsageStats()
        for i in 0..<40 {
            stats.record(text: "palavra", spokenSeconds: 1, at: day1.addingTimeInterval(Double(i) * 86_400))
        }
        let end = day1.addingTimeInterval(39 * 86_400)
        #expect(stats.lastDays(30, endingAt: end).allSatisfy { $0.words == 1 })
        #expect(stats.storedDays <= UsageStats.daysKept)
    }

    @Test func decodesOldSavedStatsWithoutDailyData() throws {
        let old = #"{"totalWords":10,"dictations":2,"spokenSeconds":5,"todayKey":"","todayWords":0}"#
        let stats = try JSONDecoder().decode(UsageStats.self, from: Data(old.utf8))
        #expect(stats.totalWords == 10)
        #expect(stats.lastDays(7).allSatisfy { $0.words == 0 })
    }
}

@Suite struct LegacyStatsTests {
    @Test func keepsTodaysWordsFromOldFormat() throws {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        let key = "\(c.year!)-\(c.month!)-\(c.day!)"
        let old = #"{"totalWords":10,"dictations":2,"spokenSeconds":5,"todayKey":"\#(key)","todayWords":7}"#
        let stats = try JSONDecoder().decode(UsageStats.self, from: Data(old.utf8))
        #expect(stats.wordsToday() == 7)
    }
}

