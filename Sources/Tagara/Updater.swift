import AppKit
import Foundation
import Observation
import TagaraCore

/// Checks GitHub Releases for a newer Tagara and installs it in place.
/// No server of our own: one small request to the GitHub API on launch and once a day.
/// The update is the release's DMG, and it's installed only if its app is signed with the
/// Tagara release certificate (scripts/release-signing.sh); no script is ever downloaded and run.
@MainActor @Observable
final class Updater {
    enum Status: Equatable {
        case idle, checking, upToDate
        case available(String)
        case installing
        case failed(String)
        /// Built locally (scripts/install.sh): never replaced by a release.
        case development
    }

    private static let repo = "mateusfonsek/tagara"
    private static let checkInterval = Duration.seconds(24 * 60 * 60)

    private(set) var status: Status = .idle
    let currentText = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    private let current: AppVersion?

    var autoCheck: Bool {
        didSet {
            UserDefaults.standard.set(autoCheck, forKey: "autoCheckUpdates")
            schedule()
        }
    }

    private var loop: Task<Void, Never>?
    private var latestDMG: URL?

    init() {
        current = AppVersion(currentText)
        autoCheck = UserDefaults.standard.object(forKey: "autoCheckUpdates") as? Bool ?? true
        if current == nil { status = .development }
    }

    var availableVersion: String? {
        if case .available(let version) = status { version } else { nil }
    }

    /// Checks shortly after launch and then daily, while automatic checks are on.
    func schedule() {
        loop?.cancel()
        guard autoCheck, current != nil else { return }
        loop = Task {
            try? await Task.sleep(for: .seconds(10))
            while !Task.isCancelled {
                await check()
                try? await Task.sleep(for: Self.checkInterval)
            }
        }
    }

    func check() async {
        guard let current else { return }
        status = .checking
        do {
            var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest")!)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("Tagara/\(currentText)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let release = try LatestRelease.parse(data)
            latestDMG = release.dmg
            status = release.version > current && release.dmg != nil ? .available(release.version.description) : .upToDate
        } catch {
            status = .failed("Não consegui verificar agora.")
        }
    }

    /// Downloads and checks the new version, then quits; a small helper swaps the app and reopens it.
    func install() {
        guard let dmg = latestDMG else { return }
        status = .installing
        Task {
            do {
                let staged = try await UpdateInstaller.download(dmg)
                try UpdateInstaller.swapAfterQuit(Bundle.main.bundleURL, with: staged)
                NSApp.terminate(nil)
            } catch {
                status = .failed("A atualização falhou. Tenta de novo?")
            }
        }
    }
}
