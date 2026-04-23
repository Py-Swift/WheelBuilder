//
//  Platforms.swift
//  WheelBuilder
//
//  Created by CodeBuilder on 07/10/2025.
//
import PlatformInfo
import PathKit
import Tools
import Foundation

extension Path: @unchecked Sendable {}

public class Iphoneos: PlatformProtocol, @unchecked Sendable {
    public static let sdk: SDK = .iphoneos
    
    public static let arch: Arch = .arm64
    
    public var cflags: Env.CFlags
    
    public var ldflags: Env.LDFlags
    
    public init() throws {
        self.cflags = .init(sdk_root: try Process.get_sdk(sdk: Self.sdk))
        self.ldflags = .init(arch: Self.arch)
    }
    
}

public class IphoneSimulator_arm64: PlatformProtocol {
    public static let sdk: SDK = .iphonesimulator
    
    public static let arch: Arch = .arm64
    
    public var cflags: Env.CFlags
    
    public var ldflags: Env.LDFlags
    
    public init() throws {
        self.cflags = .init(sdk_root: try Process.get_sdk(sdk: Self.sdk))
        self.ldflags = .init(arch: Self.arch)
    }
    
}

public class IphoneSimulator_x86_64: PlatformProtocol {
    public static let sdk: SDK = .iphonesimulator
    
    public static let arch: Arch = .x86_64
    
    public var cflags: Env.CFlags
    
    public var ldflags: Env.LDFlags
    
    public init() throws {
        self.cflags = .init(sdk_root: try Process.get_sdk(sdk: Self.sdk))
        self.ldflags = .init(arch: Self.arch)
    }
    
}

public protocol AndroidPlatform: PlatformProtocol {

}

extension AndroidPlatform {
    
}

public class Android_x86_64: PlatformProtocol, @unchecked Sendable {
    
    public static var sdk: SDK { .android }
    
    public static let arch: Arch = .x86_64
    
    public var cflags: Env.CFlags
    
    public var ldflags: Env.LDFlags
            
    public var wheel_file_platform: String { "android_\(Process.android_api_level)_x86_64" }
    
    public init() throws {
        let sysroot = try Process.get_sdk(sdk: Self.sdk)
        let api = Process.android_api_level
        self.cflags = .init(elements: [
            .include(sysroot + "usr/include"),
            .include(sysroot + "usr/include/x86_64-linux-android"),
        ])
        self.ldflags = .init(elements: [
            .library(sysroot + "usr/lib/x86_64-linux-android/\(api)"),
        ])
    }
    
}

public class Android_arm64: PlatformProtocol, @unchecked Sendable {
    
    public static var sdk: SDK { .android }
    
    public static let arch: Arch = .arm64
    
    public var cflags: Env.CFlags
    
    public var ldflags: Env.LDFlags
    
    public var wheel_file_platform: String { "android_\(Process.android_api_level)_arm64_v8a" }
    
    public init() throws {
        let sysroot = try Process.get_sdk(sdk: Self.sdk)
        let api = Process.android_api_level
        self.cflags = .init(elements: [
            .include(sysroot + "usr/include"),
            .include(sysroot + "usr/include/aarch64-linux-android"),
        ])
        self.ldflags = .init(elements: [
            .library(sysroot + "usr/lib/aarch64-linux-android/\(api)"),
        ])
    }
    
}
