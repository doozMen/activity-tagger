// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Package Version: 0.1.0

import PackageDescription

let package = Package(
    name: "aw-context",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.19.0"),
        .package(url: "https://github.com/doozMen/SwiftDateParser.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AWContextLib",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "SwiftDateParser", package: "SwiftDateParser")
            ],
            path: "Sources/AWContextLib"
        ),
        .executableTarget(
            name: "aw-context",
            dependencies: ["AWContextLib"],
            path: "Sources/AWContext"
        ),
        .testTarget(
            name: "AWContextTests",
            dependencies: ["AWContextLib"],
            path: "Tests/AWContextTests",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
    ]
)
