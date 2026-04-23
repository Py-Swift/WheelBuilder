//
//  WheelProtocol.swift
//  WheelBuilder
//

import Foundation
import PlatformInfo
import Tools
import PathKit
import Platforms

public protocol WheelProtocol {
    static var name: String { get }
    var version: String? { get set }
    //var output: Path { get }
    var build_target: BuildTarget { get }
    
    
    //associatedtype Platform: PlatformProtocol
    var platform: any PlatformProtocol { get set }
    
    var root: Path { get set }
    
    
    
    
    func urls() -> [URL]
    func env() throws -> [String:String]
    
    func patches() -> [URL]
    func apply_patches(target: Path, working_dir: Path) async throws
    
    func pre_build(target: Path) async throws
    func _build_wheel(output: Path) async throws -> Bool
    
    func get_cflags() -> Env.CFlags
    func get_ldflags() -> Env.LDFlags
    
    func dependencies_libraries() -> [any LibraryWheelProtocol.Type]
    
    static func supported_platforms() throws -> [any PlatformProtocol]
}


public extension WheelProtocol {
    
    
    
    func patches() -> [URL] {[]}
    
    func apply_patches(target: Path, working_dir: Path) async throws {
        for url in patches() {
            let patch_file = try await downloadURL(url: url, to: working_dir)
            
            try await patch(file: patch_file, target: target)
        }
    }
    
    static func supported_platforms() throws -> [any PlatformProtocol] {
        [
            try Platforms.Iphoneos(),
            try Platforms.IphoneSimulator_arm64(),
            try Platforms.IphoneSimulator_x86_64(),
            try Platforms.Android_arm64(),
            try Platforms.Android_x86_64()
        ]
    }
}
