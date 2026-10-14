import AVFoundation
import AudioToolbox
import os

/// Captures microphone audio as 16 kHz mono Float32, in memory only.
/// The engine exists only between `start()` and `stop()`, so the mic is closed while idle.
final class AudioRecorder {
    static let sampleRate = 16_000.0

    /// Called on the audio thread with a 0...1 loudness value.
    var onLevel: ((Float) -> Void)?

    private var engine: AVAudioEngine?
    private var converter: AVAudioConverter?
    private let samples = OSAllocatedUnfairLock(initialState: [Float]())
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)!

    /// Starts capture from the microphone with this Core Audio UID, or from the system default
    /// when it's nil or the device is gone.
    func start(deviceUID: String? = nil) throws {
        stop()
        samples.withLock { $0.removeAll(keepingCapacity: true) }

        let engine = AVAudioEngine()
        let input = engine.inputNode
        if let deviceUID { Self.use(deviceUID, on: input) }
        let inputFormat = input.outputFormat(forBus: 0)
        guard inputFormat.channelCount > 0, inputFormat.sampleRate > 0 else {
            throw RecorderError.noInputDevice
        }
        let converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        self.converter = converter

        input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.append(buffer)
        }
        engine.prepare()
        try engine.start()
        self.engine = engine
    }

    /// Stops capture and returns everything recorded since `start()`.
    @discardableResult
    func stop() -> [Float] {
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        engine = nil
        converter = nil
        return samples.withLock { buffer in
            defer { buffer = [] }
            return buffer
        }
    }

    /// Points the engine's input at a specific device. Must run before the input format is read.
    /// On failure (device unplugged a moment ago) the engine keeps the system default.
    private static func use(_ uid: String, on input: AVAudioInputNode) {
        guard var deviceID = AudioDevices.deviceID(forUID: uid), let unit = input.audioUnit else { return }
        AudioUnitSetProperty(
            unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0,
            &deviceID, UInt32(MemoryLayout<AudioDeviceID>.size))
    }

    private func append(_ buffer: AVAudioPCMBuffer) {
        guard let converter else { return }
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var consumed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        guard error == nil, let data = out.floatChannelData?[0] else { return }
        let chunk = Array(UnsafeBufferPointer(start: data, count: Int(out.frameLength)))
        samples.withLock { $0.append(contentsOf: chunk) }

        var sum: Float = 0
        for s in chunk { sum += s * s }
        let rms = chunk.isEmpty ? 0 : (sum / Float(chunk.count)).squareRoot()
        onLevel?(min(1, rms * 12))
    }

    enum RecorderError: LocalizedError {
        case noInputDevice
        var errorDescription: String? { "Nenhum microfone disponível" }
    }
}
