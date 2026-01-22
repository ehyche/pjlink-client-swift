// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pjlink-client-swift",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras.git", from: "1.3.2"),
    ],
    targets: [
        .executableTarget(
            name: "PJLinkClientCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "PJLinkClient"),
            ]
        ),
        .executableTarget(
            name: "PJLinkServerCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "PJLinkServer"),
            ]
        ),
        .target(
            name: "PJLinkClient",
            dependencies: [
                .target(name: "PJLinkCommon"),
            ]
        ),
        .target(
            name: "PJLinkServer",
            dependencies: [
                .target(name: "PJLinkCommon"),
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
            ]
        ),
        .target(
            name: "PJLinkCommon",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "PJLinkClientTests",
            dependencies: [
                .target(name: "PJLinkClient"),
            ]
        ),
        .testTarget(
            name: "PJLinkServerTests",
            dependencies: [
                .target(name: "PJLinkServer"),
            ]
        ),
    ]
)
