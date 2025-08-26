// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FusionSpoofDetection",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FusionSpoofDetection",
            targets: ["FusionSpoofDetection"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AppliedRecognition/Spoof-Device-Detection-Ver-ID-3-Apple.git", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/AppliedRecognition/Spoof-Detection-Fasnet-Apple.git", .upToNextMajor(from: "1.0.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FusionSpoofDetection",
            dependencies: [
                .product(name: "SpoofDeviceDetectionCore", package: "Spoof-Device-Detection-Ver-ID-3-Apple"),
                .product(name: "FASnetSpoofDetectionCore", package: "Spoof-Detection-Fasnet-Apple")
            ]
        ),
        .testTarget(
            name: "FusionSpoofDetectionTests",
            dependencies: ["FusionSpoofDetection"],
            resources: [
                .process("Resources")
            ]),
    ]
)
