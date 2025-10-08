// The Swift Programming Language
// https://docs.swift.org/swift-book
import PyPi_Api
import CiWheels
import PathKit
import Tools
import Foundation
import PlatformInfo
import Platforms

public func buildCiWheels(wheel: any CiWheelProtocol, wheel_output: Path) async throws {
    try await withTemp { working_dir in
        let platforms: [any PlatformProtocol] = [
            try Platforms.Iphoneos(),
            try Platforms.IphoneSimulator_arm64(),
            try Platforms.IphoneSimulator_x86_64()
        ]
        
        for platform in platforms {
            try await wheel.build_wheel(platform: platform, working_dir: working_dir, wheels_dir: wheel_output)
        }
    }
}

public func buildMaturinWheels(wheel: any MaturinWheelProtocol, py_cache: CachedPython, wheel_output: Path) async throws {
    try await withTemp { working_dir in
        let platforms: [any PlatformProtocol] = [
            try Platforms.Iphoneos(),
            try Platforms.IphoneSimulator_arm64(),
            try Platforms.IphoneSimulator_x86_64()
        ]
        
        for platform in platforms {
            try await wheel.build_wheel(
                target: working_dir,
                platform: platform,
                py_cache: py_cache,
                output: wheel_output,
                subfix: "_x86_64.whl"
            )
        }
    }
}
