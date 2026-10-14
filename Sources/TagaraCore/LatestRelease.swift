import Foundation

/// The parts of GitHub's "latest release" JSON the updater uses.
public struct LatestRelease: Sendable {
    public let version: AppVersion
    /// The release's DMG, only over HTTPS. nil when the release has none.
    public let dmg: URL?

    public enum ParseError: Error { case notAVersion }

    public static func parse(_ data: Data) throws -> LatestRelease {
        let raw = try JSONDecoder().decode(Raw.self, from: data)
        guard let version = AppVersion(raw.tagName) else { throw ParseError.notAVersion }
        let dmg = raw.assets
            .first { $0.name.lowercased().hasSuffix(".dmg") && $0.url.hasPrefix("https://") }
            .flatMap { URL(string: $0.url) }
        return LatestRelease(version: version, dmg: dmg)
    }

    private struct Raw: Decodable {
        let tagName: String
        let assets: [Asset]
        enum CodingKeys: String, CodingKey { case tagName = "tag_name", assets }
    }

    private struct Asset: Decodable {
        let name: String
        let url: String
        enum CodingKeys: String, CodingKey { case name, url = "browser_download_url" }
    }
}
