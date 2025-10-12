//
//  Cffi.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Cffi: CiWheelProtocol {


    
    public func pre_build(target: Path) async throws {
        
    }
    
    
    
    public func get_cflags() -> Env.CFlags {
        let flags = platform.cflags
        //flags.append(value: .include(.init("/Volumes/CodeSSD/libs/libffi/\(platform.get_sdk())/include/ffi")))
        for dep in dependencies_libraries() {
            let lib = dep.new(version: nil, platform: platform, root: root)
            flags.append(contentsOf: lib.cflag_includes())
        }
        return flags
    }
    
    public func get_ldflags() -> Env.LDFlags {
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
