// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Tagara",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.17.7"),
    ],
    targets: [
        .target(name: "TagaraCore"),
        .executableTarget(
            name: "Tagara",
            dependencies: [
                "TagaraCore",
                .product(name: "FluidAudio", package: "FluidAudio"),
            ]
        ),
        .testTarget(name: "TagaraCoreTests", dependencies: ["TagaraCore"]),
    ],
    swiftLanguageModes: [.v5]
)
