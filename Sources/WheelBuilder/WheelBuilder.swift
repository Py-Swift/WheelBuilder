// The Swift Programming Language
// https://docs.swift.org/swift-book
import PyPi_Api
import CiWheels
import PathKit
import Tools
import Foundation
import PlatformInfo
import Platforms

public func buildCiWheels(wheel: any CiWheelProtocol.Type, wheel_output: Path) async throws {
    try await withTemp { working_dir in
        let platforms: [any PlatformProtocol] = [
            try Platforms.Iphoneos(),
            try Platforms.IphoneSimulator_arm64(),
            try Platforms.IphoneSimulator_x86_64()
        ]
        
        for platform in platforms {
            let wheel = wheel.new(version: nil, platform: platform, root: working_dir)
            for lib_wheel in wheel.dependencies_libraries() {
                let lib = lib_wheel.new(version: nil, platform: platform, root: working_dir)
                try await lib.pre_build_library(working_dir: working_dir)
                try await lib.build_library_platform(working_dir: working_dir)
                try await lib.post_build_library(working_dir: working_dir)
            }
            try await wheel.build_wheel(working_dir: working_dir, wheels_dir: wheel_output)
        }
    }
}


public func buildMaturinWheels(wheel: any MaturinWheelProtocol.Type, py_cache: CachedPython, wheel_output: Path) async throws {
    try await withTemp { working_dir in
        let platforms: [any PlatformProtocol] = [
            try Platforms.Iphoneos(),
            try Platforms.IphoneSimulator_arm64(),
            try Platforms.IphoneSimulator_x86_64()
        ]
        
        for platform in platforms {
            let wheel = wheel.new(version: nil, platform: platform, root: working_dir)
            
            for lib_wheel in wheel.dependencies_libraries() {
                let lib = lib_wheel.new(version: nil, platform: platform, root: working_dir)
                try await lib.pre_build_library(working_dir: working_dir)
                try await lib.build_library_platform(working_dir: working_dir)
                try await lib.post_build_library(working_dir: working_dir)
            }
            //continue
            
            try await wheel.build_wheel(
                target: working_dir,
                py_cache: py_cache,
                output: wheel_output,
                subfix: "_x86_64.whl"
            )
        }
    }
}

public func buildCiWheels(wheel: any LibraryWheelProtocol.Type, wheel_output: Path) async throws {
    try await withTemp { working_dir in
        let platforms: [any PlatformProtocol] = [
            try Platforms.Iphoneos(),
            try Platforms.IphoneSimulator_arm64(),
            try Platforms.IphoneSimulator_x86_64()
        ]
        
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
