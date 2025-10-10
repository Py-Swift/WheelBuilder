//
//  Cffi.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation


public final class Cffi: CiWheelProtocol {
    public static let name: String = "cffi"
    
    public var version: String?
    
    //public var output: Path
    public var root: Path
    
    public let build_target: BuildTarget = .pypi(name)
    
    public var platform: any PlatformProtocol
    
    init(version: String? = nil, platform: any PlatformProtocol, root: Path) {
        self.version = version
        self.platform = platform
        self.root = root
    }
    
    public static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self {
        .init(version: version, platform: platform, root: root)
    }
    
    public func pre_build(platform: any PlatformProtocol, target: Path) async throws {
        
    }
    
    
    
    public func get_cflags(platform: any PlatformProtocol) -> Env.CFlags {
        let flags = platform.cflags
        //flags.append(value: .include(.init("/Volumes/CodeSSD/libs/libffi/\(platform.get_sdk())/include/ffi")))
        for dep in dependencies_libraries() {
            let lib = dep.new(version: nil, platform: platform, root: root)
            flags.append(contentsOf: lib.cflag_includes())
        }
        return flags
    }
    
    public func get_ldflags(platform: any PlatformProtocol) -> Env.LDFlags {
        let flags = platform.ldflags
        //flags.append(value: .library(.init("/Volumes/CodeSSD/libs/libffi/\(platform.get_sdk())")))
        //flags.append(value: .library())
        for dep in dependencies_libraries() {
            let lib = dep.new(version: nil, platform: platform, root: root)
            flags.append(contentsOf: lib.ldflag_libraries())
        }
        return flags
    }
    
    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [
            Libffi.self
        ]
    }
}

extension Cffi {
    public func build_wheel(working_dir: Path, wheels_dir: Path) async throws { }
        
}
