// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AltTabAlpine",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "SwitcherCore", path: "Sources/SwitcherCore"),
        .executableTarget(
            name: "AltTabAlpine",
            dependencies: ["SwitcherCore"],
            path: "Sources/AltTabAlpine"
        ),
        .testTarget(
            name: "AltTabAlpineTests",
            dependencies: ["SwitcherCore"],
            path: "Tests/AltTabAlpineTests"
        ),
    ]
)
