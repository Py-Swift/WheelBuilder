//
//  WheelProtocol.swift
//  WheelBuilder
//

import Foundation
import PlatformInfo
import Tools
import PathKit

public protocol WheelProtocol {
    static var name: String { get }
    var version: String? { get }
    //var output: Path { get }
    var build_target: BuildTarget { get }
    
    
    //associatedtype Platform: PlatformProtocol
    var platform: any PlatformProtocol { get }
    
    
    
    func urls() -> [URL]
    func env(platform: any PlatformProtocol) throws -> [String:String]
    
    func patches() -> [URL]
    func apply_patches(target: Path, working_dir: Path) async throws
    
    func pre_build(platform: any PlatformProtocol, target: Path) async throws
    func _build_wheel(platform: any PlatformProtocol, output: Path) async throws -> Bool
    
    func get_cflags(platform: any PlatformProtocol) -> Env.CFlags
    func get_ldflags(platform: any PlatformProtocol) -> Env.LDFlags
    
    func dependencies_libraries() -> [any LibraryWheelProtocol.Type]
}


public extension WheelProtocol {
    
    func patches() -> [URL] {[]}
    
    func apply_patches(target: Path, working_dir: Path) async throws {
        for url in patches() {
            let patch_file = try await downloadURL(url: url, to: working_dir)
            
            try await patch(file: patch_file, target: target)
        }
    }
}
