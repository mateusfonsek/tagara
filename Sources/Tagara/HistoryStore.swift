import TagaraCore
import Foundation

/// Persists the dictation history as a small JSON file readable only by the user.
/// Written once per dictation; never touched while idle.
enum HistoryStore {
    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Tagara/history.json")
    }

    static func load() -> DictationHistory {
        guard let data = try? Data(contentsOf: fileURL),
              let history = try? JSONDecoder().decode(DictationHistory.self, from: data)
        else { return DictationHistory() }
        return history
    }

    static func save(_ history: DictationHistory) {
        let url = fileURL
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700])
            try JSONEncoder().encode(history).write(to: url, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        } catch {
            NSLog("Tagara: falha ao salvar histórico: \(error)")
        }
    }
}
