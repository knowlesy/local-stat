// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LocalStat",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "LocalStat",
            path: "Sources/LocalStat"
        ),
        .testTarget(
            name: "LocalStatTests",
            dependencies: ["LocalStat"],
            path: "Tests/LocalStatTests"
        )
    ]
)
