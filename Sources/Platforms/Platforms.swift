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
