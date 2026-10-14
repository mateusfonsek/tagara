import CoreAudio
import Foundation
import Observation
import TagaraCore

/// The Mac's microphones, kept up to date as devices are plugged in and out.
@MainActor
@Observable
final class AudioDevices {
    private(set) var inputs: [InputDevice] = []

    @ObservationIgnored private var listener: AudioObjectPropertyListenerBlock?

    init() {
        refresh()
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor in self?.refresh() }
        }
        var address = Self.address(kAudioHardwarePropertyDevices)
        if AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, listener) == noErr {
            self.listener = listener
        }
    }

    func refresh() {
        inputs = Self.deviceIDs().compactMap { id in
            guard Self.hasInput(id), let uid = Self.string(id, kAudioDevicePropertyDeviceUID),
                  let name = Self.string(id, kAudioObjectPropertyName) else { return nil }
            return InputDevice(uid: uid, name: name)
        }
    }

    /// Core Audio's current ID for a device UID. IDs change between boots, UIDs don't.
    nonisolated static func deviceID(forUID uid: String) -> AudioDeviceID? {
        deviceIDs().first { string($0, kAudioDevicePropertyDeviceUID) == uid }
    }

    // MARK: - Core Audio

    private nonisolated static func address(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    private nonisolated static func deviceIDs() -> [AudioDeviceID] {
        var address = address(kAudioHardwarePropertyDevices)
        let system = AudioObjectID(kAudioObjectSystemObject)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids
    }

    /// True when the device has at least one input channel (a microphone, not just speakers).
    private nonisolated static func hasInput(_ id: AudioDeviceID) -> Bool {
        var address = address(kAudioDevicePropertyStreamConfiguration, scope: kAudioObjectPropertyScopeInput)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr, size > 0 else { return false }
        let raw = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { raw.deallocate() }
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, raw) == noErr else { return false }
        let buffers = UnsafeMutableAudioBufferListPointer(raw.assumingMemoryBound(to: AudioBufferList.self))
        return buffers.contains { $0.mNumberChannels > 0 }
    }

    private nonisolated static func string(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = address(selector)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr,
              let text = value?.takeRetainedValue() else { return nil }
        return text as String
    }
}
