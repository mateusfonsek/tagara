/// A microphone the Mac can record from. `uid` is Core Audio's persistent device UID:
/// unlike the device ID, it survives reboots and reconnections.
public struct InputDevice: Equatable, Sendable {
    public let uid: String
    public let name: String

    public init(uid: String, name: String) {
        self.uid = uid
        self.name = name
    }
}

/// A row in the microphone picker. A chosen device that is unplugged stays listed, marked
/// as disconnected, so the choice isn't lost when the headset is put away.
public struct MicrophoneOption: Equatable, Sendable, Identifiable {
    public let uid: String
    public let name: String
    public let isConnected: Bool

    public var id: String { uid }

    public init(uid: String, name: String, isConnected: Bool) {
        self.uid = uid
        self.name = name
        self.isConnected = isConnected
    }
}

public enum MicrophoneChoice {
    /// The device to record from: the chosen one while it's connected. nil means the system default,
    /// both when nothing was chosen and when the chosen device is gone.
    public static func device(chosen uid: String?, available: [InputDevice]) -> InputDevice? {
        guard let uid else { return nil }
        return available.first { $0.uid == uid }
    }

    /// Picker rows: every connected microphone, plus the chosen one when it's disconnected.
    public static func options(chosen uid: String?, chosenName: String?, available: [InputDevice]) -> [MicrophoneOption] {
        var options = available.map { MicrophoneOption(uid: $0.uid, name: $0.name, isConnected: true) }
        if let uid, !available.contains(where: { $0.uid == uid }) {
            options.append(MicrophoneOption(uid: uid, name: chosenName ?? uid, isConnected: false))
        }
        return options
    }
}
