// The Swift Programming Language
// https://docs.swift.org/swift-book
import PyPi_Api
import CiWheels
import PathKit
import Tools
import Foundation
import PlatformInfo
import Platforms
import SwiftCPUDetect

public enum BuildPlatform: String, CaseIterable {
    case ios
    case android
}

func resolvePlatforms(_ filter: BuildPlatform?, wheel_type: (any WheelProtocol.Type)?) throws -> [any PlatformProtocol] {
    switch filter {
    case .ios:
        return [
            try Platforms.Iphoneos(),
            try Platforms.IphoneSimulator_arm64(),
            try Platforms.IphoneSimulator_x86_64(),
        ]
    case .android:
        return [
            try Platforms.Android_arm64(),
            try Platforms.Android_x86_64(),
        ]
    case nil:
        return try wheel_type?.supported_platforms() ?? [
            try Platforms.Iphoneos(),
            try Platforms.IphoneSimulator_arm64(),
            try Platforms.IphoneSimulator_x86_64(),
            try Platforms.Android_arm64(),
            try Platforms.Android_x86_64(),
        ]
    }
}

public func buildCiWheels(wheel: any CiWheelProtocol.Type, version: String? = nil, platform filter: BuildPlatform? = nil, wheel_output: Path) async throws {
    try await withTemp { working_dir in
        let platforms = try resolvePlatforms(filter, wheel_type: wheel)
        
        for platform in platforms {
            let wheel = wheel.new(version: nil, platform: platform, root: working_dir)
            for lib_wheel in wheel.dependencies_libraries() {
                let lib = lib_wheel.new(version: nil, platform: platform, root: working_dir)
                try await lib.pre_build_library(working_dir: working_dir)
                try await lib.build_library_platform(working_dir: working_dir)
                try await lib.post_build_library(working_dir: working_dir)
            }

            try await wheel.build_wheel(working_dir: working_dir, version: version, wheels_dir: wheel_output)
        }
    }
}


public func buildMaturinWheels(wheel: any MaturinWheelProtocol.Type, version: String? = nil, platform filter: BuildPlatform? = nil, wheel_output: Path) async throws {
    try await withTemp { working_dir in
        let platforms = try resolvePlatforms(filter, wheel_type: wheel)
        
        for platform in platforms {
            let wheel = wheel.new(version: version, platform: platform, root: working_dir)
            
            for lib_wheel in wheel.dependencies_libraries() {
                let lib = lib_wheel.new(version: nil, platform: platform, root: working_dir)
                try await lib.pre_build_library(working_dir: working_dir)
                try await lib.build_library_platform(working_dir: working_dir)
                try await lib.post_build_library(working_dir: working_dir)
            }
            
            try await wheel.build_wheel(working_dir: working_dir, version: version, wheels_dir: wheel_output)
        }
    }
}

public func buildCiWheels(wheel: any LibraryWheelProtocol.Type, platform filter: BuildPlatform? = nil, wheel_output: Path) async throws {
    try await withTemp { working_dir in
        let platforms = try resolvePlatforms(filter, wheel_type: wheel)
        
        for platform in platforms {
            
            let wheel = wheel.new(version: nil, platform: platform, root: working_dir)
            
            try await wheel.pre_build_library(working_dir: working_dir)
            try await wheel.build_library_platform(working_dir: working_dir)
            try await wheel.post_build_library(working_dir: working_dir)
        }
        let wheels = working_dir + "wheels"
        
        for p in ["iphoneos", "iphonesimulator"] {
            print(p, try (wheels + "\(p)/libffi.a").read())
        }
        
    }
}
