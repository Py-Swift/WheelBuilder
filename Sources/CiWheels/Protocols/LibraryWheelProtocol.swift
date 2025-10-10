//
//  LibraryWheelProtocol.swift
//  WheelBuilder
//
import Foundation
import PlatformInfo
import Tools
import PathKit

public protocol LibraryWheelProtocol: WheelProtocol {
    var root: Path { get set }
    func pre_build_library(working_dir: Path) async throws
    func build_library_platform(working_dir: Path) async throws
    func post_build_library(working_dir: Path) async throws
    
    func cflag_includes() -> [Env.CFlags.Value]
    func ldflag_libraries() -> [Env.LDFlags.Value]
    
    static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self
}

public extension LibraryWheelProtocol {
    func urls() -> [URL] {[]}
    
    
    func pre_build(platform: any PlatformProtocol, target: Path) async throws {}
    func _build_wheel(platform: any PlatformProtocol, output: Path) async throws -> Bool { false }
    
    func get_cflags(platform: any PlatformProtocol) -> Env.CFlags {
        platform.cflags
    }
    
    func cflag_includes() -> [Env.CFlags.Value] {
        [.include(include_dir())]
    }
    
    func ldflag_libraries() -> [Env.LDFlags.Value] {
        [.library(lib_dir())]
    }
    
    func get_ldflags(platform: any PlatformProtocol) -> Env.LDFlags {
        platform.ldflags
    }
    
    func base_env(platform: any PlatformProtocol) -> [String:String] {
        [
            "CFLAGS": get_cflags(platform: platform).description,
            "LDFLAGS": get_ldflags(platform: platform).description
        ] + processInfo.environment
    }
    
    func env(platform: any PlatformProtocol) throws -> [String : String] {
        base_env(platform: platform)
    }
    
    func build_library_platform(working_dir: Path) async throws {
        try await pre_build(platform: platform, target: working_dir)
    }
    
    func build_wheel(working_dir: Path, wheels_dir: Path) async throws {
        
        if try await _build_wheel(platform: platform, output: working_dir) { return }
        
    }
    
    func include_dir() -> Path {
        root + "\(platform.get_sdk())_\(platform.get_arch())/include"
    }
    
    func lib_dir() -> Path {
        root + "\(platform.get_sdk())_\(platform.get_arch())/lib"
    }
    
    func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        []
    }
}
