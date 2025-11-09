// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

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
        .library(name: "PipRepo", targets: ["PipRepo"]),
//        .library(
//            name: "WheelBuilderMacros",
//            targets: ["WheelBuilderMacros"]),
        .executable(name: "WheelBuilderCLI", targets: ["WheelBuilderCLI"])
    ],
    dependencies: [
        //.package(path: "../PyPi_Api"),
        .package(url: "https://github.com/Py-Swift/PyPi_Api", branch: "master"),
        .package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.1")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.6.1")),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", .upToNextMajor(from: "1.2.1")),
        .package(url: "https://github.com/ITzTravelInTime/SwiftCPUDetect.git", from: "1.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WheelBuilder",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "CiWheels"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "PlatformInfo",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "PathKit"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "Platforms",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "PlatformInfo",
                "PathKit",
                "Tools"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "CiWheels",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "PlatformInfo",
                "PathKit",
                "Tools",
                "Platforms",
                "WheelBuilderMacros",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .byName(name: "SwiftCPUDetect"),
                
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "Tools",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "PlatformInfo",
                "PathKit"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "PipRepo",
            dependencies: [
                .byName(name: "PyPi_Api"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                "PlatformInfo",
                "PathKit"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "WheelBuilderCLI",
            dependencies: [
                .byName(name: "PyPi_Api"),
                "CiWheels",
                "WheelBuilder",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "PipRepo"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .macro(
            name: "WheelBuilderMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        
        .testTarget(
            name: "WheelBuilderTests",
            dependencies: ["WheelBuilder"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
    ]
)
