import FluidAudio
import Foundation

protocol Transcriber: AnyObject, Sendable {
    func transcribe(_ samples: [Float]) async throws -> String
}

/// Parakeet Ultra running on the Neural Engine via FluidAudio.
final class ParakeetTranscriber: Transcriber, @unchecked Sendable {
    static let version: AsrModelVersion = .ultra

    private let manager: AsrManager

    private init(manager: AsrManager) {
        self.manager = manager
    }

    static var modelDirectory: URL { AsrModels.defaultCacheDirectory(for: version) }

    static var isDownloaded: Bool {
        AsrModels.modelsExist(at: modelDirectory, version: version)
    }

    static func download(progress: @escaping @Sendable (Double) -> Void) async throws {
        try await AsrModels.download(version: version) { progress($0.fractionCompleted) }
    }

    static func load() async throws -> ParakeetTranscriber {
        let models = try await AsrModels.load(from: modelDirectory, version: version)
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        return ParakeetTranscriber(manager: manager)
    }

    func transcribe(_ samples: [Float]) async throws -> String {
        var state = TdtDecoderState.make(decoderLayers: await manager.decoderLayerCount)
        return try await manager.transcribe(samples, decoderState: &state).text
    }

    func unload() async {
        await manager.cleanup()
    }
}
