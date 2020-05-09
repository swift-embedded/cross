// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Cross",
    products: [
        .executable(
            name: "cross",
            targets: ["cross"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-embedded/swift-package-manager", .branch("embedded-5.1")),
        .package(url: "https://github.com/dduan/TOMLDecoder", from: "0.1.3"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "CrossLib",
            dependencies: ["SwiftPM-auto", "SPMUtility", "TOMLDecoder"]
        ),
        .target(
            name: "cross",
            dependencies: ["CrossLib", .product(name: "ArgumentParser", package: "swift-argument-parser"),]
        ),
    ]
)
