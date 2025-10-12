//
//  LibraryWheelProtocol.swift
//  WheelBuilder
//
import Foundation
import PlatformInfo
import Tools
import PathKit

public protocol LibraryWheelProtocol: WheelProtocol {
    
    init(version: String?, platform: any PlatformProtocol, root: Path)
    
    var root: Path { get set }
    func pre_build_library(working_dir: Path) async throws
    func build_library_platform(working_dir: Path) async throws
    func post_build_library(working_dir: Path) async throws
    
    func cflag_includes() -> [Env.CFlags.Value]
    func ldflag_libraries() -> [Env.LDFlags.Value]
    
    static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self
}

public extension LibraryWheelProtocol {
    
    static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self {
        .init(version: version, platform: platform, root: root + Self.name)
    }
    
    func urls() -> [URL] {[]}
    
    
    func pre_build(target: Path) async throws {}
    func _build_wheel(output: Path) async throws -> Bool { false }
    
    func get_cflags() -> Env.CFlags {
        platform.cflags
    }
    
    func cflag_includes() -> [Env.CFlags.Value] {
        [.include(include_dir())]
    }
    
    func ldflag_libraries() -> [Env.LDFlags.Value] {
        [.library(lib_dir())]
    }
    
    func get_ldflags() -> Env.LDFlags {
        platform.ldflags
    }
    
    func base_env() -> [String:String] {
        [
            "CFLAGS": get_cflags().description,
            "LDFLAGS": get_ldflags().description
        ] + processInfo.environment
    }
    
    func env() throws -> [String : String] {
        base_env()
    }
    
    func build_library_platform(working_dir: Path) async throws {
        try await pre_build(target: working_dir)
    }
    
    func build_wheel(working_dir: Path, wheels_dir: Path) async throws {
        
        if try await _build_wheel(output: working_dir) { return }
        
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
