import AppKit
import Foundation
import Observation
import TagaraCore

/// Checks GitHub Releases for a newer Tagara and installs it with the one-line installer.
/// No server of our own: one small request to the GitHub API on launch and once a day.
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
    private static let installer = "https://raw.githubusercontent.com/\(repo)/main/scripts/get.sh"
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
            let release = try JSONDecoder().decode(Release.self, from: data)
            guard let latest = AppVersion(release.tagName) else { throw URLError(.cannotParseResponse) }
            status = latest > current ? .available(latest.description) : .upToDate
        } catch {
            status = .failed("Não consegui verificar agora.")
        }
    }

    /// Runs the installer, which quits this app, replaces it in place and reopens it.
    func install() {
        status = .installing
        let folder = Bundle.main.bundleURL.deletingLastPathComponent().path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "curl -fsSL \(Self.installer) | DEST='\(folder)' bash"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            status = .failed("Não consegui iniciar a atualização.")
        }
    }

    private struct Release: Decodable {
        let tagName: String
        enum CodingKeys: String, CodingKey { case tagName = "tag_name" }
    }
}
