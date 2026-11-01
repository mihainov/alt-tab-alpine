// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AltTab",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "SwitcherCore", path: "Sources/SwitcherCore"),
        .executableTarget(
            name: "AltTab",
            dependencies: ["SwitcherCore"],
            path: "Sources/AltTab"
        ),
        .testTarget(
            name: "AltTabTests",
            dependencies: ["SwitcherCore"],
            path: "Tests/AltTabTests"
        ),
    ]
)
