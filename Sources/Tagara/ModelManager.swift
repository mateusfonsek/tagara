import Foundation
import Observation

/// Owns the model lifecycle: first-run download, on-demand load, idle unload.
@MainActor @Observable
final class ModelManager {
    enum Status: Equatable {
        case notDownloaded
        case downloading(Double)
        case unloaded
        case loading
        case loaded
        case failed(String)
    }

    private(set) var status: Status
    /// Minutes of inactivity before freeing the model's memory. 0 = never.
    var unloadAfterMinutes: Int {
        didSet { UserDefaults.standard.set(unloadAfterMinutes, forKey: "unloadAfterMinutes") }
    }

    private var transcriber: ParakeetTranscriber?
    private var loadTask: Task<ParakeetTranscriber, Error>?
    private var unloadTask: Task<Void, Never>?

    init() {
        status = ParakeetTranscriber.isDownloaded ? .unloaded : .notDownloaded
        unloadAfterMinutes = UserDefaults.standard.object(forKey: "unloadAfterMinutes") as? Int ?? 10
    }

    var isDownloaded: Bool {
        switch status {
        case .notDownloaded, .downloading: false
        case .failed: ParakeetTranscriber.isDownloaded
        default: true
        }
    }

    func download() async {
        if case .downloading = status { return }
        status = .downloading(0)
        do {
            try await ParakeetTranscriber.download { fraction in
                Task { @MainActor in
                    if case .downloading = self.status { self.status = .downloading(fraction) }
                }
            }
            status = .unloaded
            prewarm()
        } catch {
            status = .failed("Falha no download: \(error.localizedDescription)")
        }
    }

    /// Starts loading in the background so it overlaps with the user speaking.
    func prewarm() {
        unloadTask?.cancel()
        guard isDownloaded else { return }
        Task { _ = try? await ensureLoaded() }
    }

    func ensureLoaded() async throws -> ParakeetTranscriber {
        if let transcriber { return transcriber }
        if let loadTask { return try await loadTask.value }
        status = .loading
        let task = Task { try await ParakeetTranscriber.load() }
        loadTask = task
        defer { loadTask = nil }
        do {
            let loaded = try await task.value
            transcriber = loaded
            status = .loaded
            return loaded
        } catch {
            status = .failed("Falha ao carregar o modelo: \(error.localizedDescription)")
            throw error
        }
    }

    /// Called after each dictation; frees memory if nothing happens for a while.
    func scheduleUnload() {
        unloadTask?.cancel()
        guard unloadAfterMinutes > 0 else { return }
        let delay = Duration.seconds(unloadAfterMinutes * 60)
        unloadTask = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await unload()
        }
    }

    func unload() async {
        guard let transcriber else { return }
        self.transcriber = nil
        status = .unloaded
        await transcriber.unload()
    }
}
