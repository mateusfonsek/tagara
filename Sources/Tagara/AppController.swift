import AppKit
import TagaraCore
import Observation
import ServiceManagement

/// Orchestrates hotkey → recording → transcription → paste.
@MainActor @Observable
final class AppController {
    static let shared = AppController()

    enum Phase: Equatable {
        case idle, recording, transcribing
        case notice(String)
    }

    /// Recordings shorter than this are accidental taps and get discarded.
    private static let minimumSeconds = 0.3

    private(set) var phase: Phase = .idle
    private(set) var level: Float = 0
    /// True after a double tap on ⌥: recording continues until the next tap.
    private(set) var handsFree = false
    private(set) var stats: UsageStats
    private(set) var hasMicrophone = Permissions.microphone
    private(set) var hasAccessibility = Permissions.accessibility
    private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled

    private(set) var history = HistoryStore.load()
    /// Kept in memory even when history is off, so "Copiar último ditado" always works.
    private(set) var lastTranscript: String?

    var historyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(historyEnabled, forKey: "historyEnabled")
            if !historyEnabled { clearHistory() }
        }
    }

    var soundsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundsEnabled, forKey: "soundsEnabled") }
    }

    /// Double tap on ⌥ locks recording hands-free.
    var handsFreeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(handsFreeEnabled, forKey: "handsFreeEnabled")
            hotkey.handsFreeEnabled = handsFreeEnabled
        }
    }

    /// The chosen microphone's Core Audio UID; nil follows the system default.
    private(set) var microphoneUID: String?
    /// Its name, kept so an unplugged choice still reads well in the picker.
    private var microphoneName: String?

    let models = ModelManager()
    let updater = Updater()
    let audioDevices = AudioDevices()
    /// Set by the SwiftUI layer, which owns window scenes.
    var openMainWindow: (() -> Void)?

    private let hotkey = HotkeyMonitor()
    private let recorder = AudioRecorder()
    @ObservationIgnored private lazy var overlay = OverlayController(controller: self)
    private var recordingStartedAt = Date()
    /// The app in front when recording began: the only one the text may be pasted into.
    private var recordingApp: NSRunningApplication?
    private var noticeTask: Task<Void, Never>?

    private init() {
        soundsEnabled = UserDefaults.standard.object(forKey: "soundsEnabled") as? Bool ?? true
        historyEnabled = UserDefaults.standard.object(forKey: "historyEnabled") as? Bool ?? true
        handsFreeEnabled = UserDefaults.standard.object(forKey: "handsFreeEnabled") as? Bool ?? true
        microphoneUID = UserDefaults.standard.string(forKey: "microphoneUID")
        microphoneName = UserDefaults.standard.string(forKey: "microphoneName")
        if let data = UserDefaults.standard.data(forKey: "stats"),
           let saved = try? JSONDecoder().decode(UsageStats.self, from: data) {
            stats = saved
        } else {
            stats = UsageStats()
        }
        hotkey.handsFreeEnabled = handsFreeEnabled
        hotkey.onEvent = { [weak self] output in self?.handle(output) }
        recorder.onLevel = { [weak self] value in
            Task { @MainActor in self?.level = value }
        }
    }

    /// Picker rows: the connected microphones, plus the chosen one if it's unplugged.
    var microphoneOptions: [MicrophoneOption] {
        MicrophoneChoice.options(chosen: microphoneUID, chosenName: microphoneName, available: audioDevices.inputs)
    }

    /// nil goes back to the system default.
    func chooseMicrophone(uid: String?) {
        microphoneUID = uid
        microphoneName = uid.map { uid in audioDevices.inputs.first { $0.uid == uid }?.name ?? microphoneName ?? uid }
        UserDefaults.standard.set(microphoneUID, forKey: "microphoneUID")
        UserDefaults.standard.set(microphoneName, forKey: "microphoneName")
    }

    var needsSetup: Bool { !hasMicrophone || !hasAccessibility || !models.isDownloaded }
    var isReady: Bool { !needsSetup && hotkey.isRunning }

    func start() {
        updater.schedule()
        refreshPermissions()
        if needsSetup { openMainWindow?() }
    }

    /// Cheap checks; called when the window is visible or the app becomes active.
    func refreshPermissions() {
        hasMicrophone = Permissions.microphone
        hasAccessibility = Permissions.accessibility
        if hasAccessibility && !hotkey.isRunning { hotkey.start() }
    }

    func requestMicrophone() async {
        hasMicrophone = await Permissions.requestMicrophone()
    }

    func requestAccessibility() {
        Permissions.requestAccessibility()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            showNotice("Não consegui mudar isso: \(error.localizedDescription)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - History

    func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func copyLastTranscript() {
        if let text = lastTranscript ?? history.entries.first?.text { copy(text) }
    }

    func removeHistoryEntry(_ id: UUID) {
        history.remove(id: id)
        HistoryStore.save(history)
    }

    func clearHistory() {
        history.clear()
        HistoryStore.save(history)
    }

    // MARK: - Dictation flow

    private func handle(_ output: HotkeyStateMachine.Output) {
        switch output {
        case .press: beginRecording()
        case .release: finishRecording()
        case .cancel: cancelRecording()
        case .lock: if phase == .recording { handsFree = true }
        case .restart:
            cancelRecording()
            beginRecording()
        }
    }

    private func beginRecording() {
        guard phase == .idle || isNotice else { return }
        guard hasMicrophone, models.isDownloaded else {
            refreshPermissions()
            showNotice(models.isDownloaded ? "Não tô te ouvindo. Libera o microfone?" : "Falta baixar o modelo de voz.")
            openMainWindow?()
            return
        }
        models.prewarm()
        do {
            let device = MicrophoneChoice.device(chosen: microphoneUID, available: audioDevices.inputs)
            try recorder.start(deviceUID: device?.uid)
        } catch {
            showNotice(error.localizedDescription)
            return
        }
        recordingStartedAt = Date()
        recordingApp = NSWorkspace.shared.frontmostApplication
        phase = .recording
        play("Tink")
        overlay.show()
    }

    private func cancelRecording() {
        guard phase == .recording else { return }
        recorder.stop()
        endSession()
    }

    private func finishRecording() {
        guard phase == .recording else { return }
        let samples = recorder.stop()
        let seconds = Double(samples.count) / AudioRecorder.sampleRate
        guard seconds >= Self.minimumSeconds else {
            endSession()
            return
        }
        phase = .transcribing
        handsFree = false
        level = 0
        Task {
            do {
                let transcriber = try await models.ensureLoaded()
                let text = TextCleanup.clean(try await transcriber.transcribe(samples))
                var switchedApps = false
                if !text.isEmpty {
                    let app = recordingApp?.localizedName
                    switch PasteTarget.decide(
                        startedIn: recordingApp?.processIdentifier,
                        frontmostNow: NSWorkspace.shared.frontmostApplication?.processIdentifier)
                    {
                    case .paste: TextInserter.insert(text)
                    case .copyOnly:
                        copy(text)
                        switchedApps = true
                    }
                    lastTranscript = text
                    if historyEnabled {
                        history.add(text: text, app: app)
                        HistoryStore.save(history)
                    }
                    stats.record(text: text, spokenSeconds: seconds)
                    saveStats()
                    play("Pop")
                }
                endSession()
                if switchedApps { showNotice("Você trocou de app. O texto ficou copiado, é só ⌘V.") }
            } catch {
                endSession()
                showNotice("Não consegui escrever essa. Tenta de novo?")
            }
            models.scheduleUnload()
        }
    }

    private func endSession() {
        phase = .idle
        handsFree = false
        level = 0
        overlay.hide()
    }

    private var isNotice: Bool {
        if case .notice = phase { true } else { false }
    }

    private func showNotice(_ message: String) {
        phase = .notice(message)
        overlay.show()
        noticeTask?.cancel()
        noticeTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled, isNotice else { return }
            endSession()
        }
    }

    private func play(_ name: String) {
        guard soundsEnabled, let sound = NSSound(named: name) else { return }
        sound.volume = 0.25
        sound.play()
    }

    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: "stats")
        }
    }
}
