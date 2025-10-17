// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pjlink-client-swift",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "pjlink-client-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "pjlink-client-lib"),
            ]
        ),
        .target(
            name: "pjlink-client-lib",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "pjlink-client-lib-tests",
            dependencies: [
                .target(name: "pjlink-client-lib"),
            ]
        ),
    ]
)
