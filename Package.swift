// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WheelBuilder",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WheelBuilder",
            targets: ["WheelBuilder"]),
    ],
    dependencies: [
        .package(path: "../PyPi_Api"),
        .package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WheelBuilder",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "CiWheels"
            ]
        ),
        .target(
            name: "PlatformInfo",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "PathKit"
            ]
        ),
        .target(
            name: "Platforms",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "PlatformInfo",
                "PathKit",
                "Tools"
            ]
        ),
        .target(
            name: "CiWheels",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "PlatformInfo",
                "PathKit",
                "Tools",
                "Platforms"
            ]
        ),
        .target(
            name: "Tools",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "PlatformInfo",
                "PathKit"
            ]
        ),
        .testTarget(
            name: "WheelBuilderTests",
            dependencies: ["WheelBuilder"]
        ),
    ]
)
