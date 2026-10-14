import Foundation
import Security

/// Installs an update from a release DMG. Runs off the main thread: mounting and copying take seconds.
/// Nothing from the network is executed; the new app is used only if it's signed by the release
/// certificate (scripts/release-signing.sh).
enum UpdateInstaller {
    /// Who may sign an update: our bundle ID and the release certificate, pinned by its SHA-1.
    static let signer =
        #"identifier "dev.fonsek.tagara" and certificate leaf = H"522bc209a9473132a19a61ae6583afcd073a220b""#

    /// The new Tagara.app, copied out of the DMG into a temporary folder and verified.
    static func download(_ dmg: URL) async throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "tagara-update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let (downloaded, response) = try await URLSession.shared.download(from: dmg)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateError.download }
        let image = folder.appending(path: "Tagara.dmg")
        try FileManager.default.moveItem(at: downloaded, to: image)

        let mount = folder.appending(path: "mount")
        try run("/usr/bin/hdiutil", "attach", image.path, "-nobrowse", "-readonly", "-noautoopen", "-mountpoint", mount.path)
        defer { try? run("/usr/bin/hdiutil", "detach", mount.path, "-quiet") }
        let app = folder.appending(path: "Tagara.app")
        try run("/usr/bin/ditto", mount.appending(path: "Tagara.app").path, app.path)
        try verify(app)
        return app
    }

    /// Fails unless the app is intact and signed by the release certificate.
    static func verify(_ app: URL) throws {
        var code: SecStaticCode?
        var requirement: SecRequirement?
        guard SecStaticCodeCreateWithPath(app as CFURL, [], &code) == errSecSuccess, let code,
              SecRequirementCreateWithString(signer as CFString, [], &requirement) == errSecSuccess,
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate | kSecCSCheckAllArchitectures), requirement) == errSecSuccess
        else { throw UpdateError.signature }
    }

    /// Starts a helper that waits for this process to exit, puts the new app in place of the
    /// old one (restoring the old one if the move fails) and opens it. Paths go in as arguments,
    /// never inside the script text.
    static func swapAfterQuit(_ current: URL, with staged: URL) throws {
        let script = """
            while kill -0 "$1" 2>/dev/null; do sleep 0.2; done
            mv "$3" "$3.old" || exit 1
            if mv "$2" "$3"; then rm -rf "$3.old"; else mv "$3.old" "$3"; fi
            xattr -dr com.apple.quarantine "$3" 2>/dev/null
            open "$3"
            """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script, "tagara-update", String(ProcessInfo.processInfo.processIdentifier), staged.path, current.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    private static func run(_ tool: String, _ arguments: String...) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw UpdateError.tool(tool) }
    }

    enum UpdateError: Error {
        case download, signature
        case tool(String)
    }
}
