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
        guard platform.get_sdk() == .android else { return }
        // Patch setup.py: replace hardcoded /usr/include/ffi with the actual
        // libffi path we downloaded, disable host pkg-config, and set library_dirs.
        let libffi = Libffi.new(version: nil, platform: platform, root: root)
        let ffiInc = (libffi.include_dir() + "ffi").string
        let ffiLib = libffi.lib_dir().string
        let setup = target + "setup.py"
        guard setup.exists else { return }
        var contents = try String(contentsOf: setup.url)
        contents = contents.replacingOccurrences(
            of: "include_dirs = ['/usr/include/ffi',\n                '/usr/include/libffi']    # may be changed by pkg-config",
            with: "include_dirs = ['\(ffiInc)']"
        )
        contents = contents.replacingOccurrences(
            of: "library_dirs = []",
            with: "library_dirs = ['\(ffiLib)']"
        )
        contents = contents.replacingOccurrences(
            of: "else:\n    use_pkg_config()",
            with: "else:\n    pass"
        )
        try contents.write(to: setup.url, atomically: true, encoding: .utf8)
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
