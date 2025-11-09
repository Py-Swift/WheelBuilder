//
//  Libffi.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@LibraryClass
public final class Libffi: LibraryWheelProtocol {
    
    static let default_version: String = "3.4.7-2"

    
    public var build_target: BuildTarget {
        let v = version ?? Self.default_version
        let sdk = platform.get_sdk()
        let arch = platform.get_arch()
        return .url(
            //"https://github.com/libffi/libffi/releases/download/v\(v)/libffi-\(v).tar.gz"
            "https://github.com/beeware/cpython-apple-source-deps/releases/download/libFFI-\(v)/libffi-\(v)-\(sdk).\(arch).tar.gz"
        )
    }


    public func pre_build_library(working_dir: Path) async throws {
        
        //guard platform.get_sdk() == .iphoneos else { return }
        
        switch build_target {
        case .url(let url):
            try await downloadTarFile(url: url, to: working_dir)
            //libffi = try pip_download(name: "libffi==\(version ?? Self.default_version)", output: working_dir)
            
        default:
            return
        }
        let libffi: Path = working_dir //+ "libffi-\(version ?? Self.default_version)"
        
        for file in try working_dir.children() {
            print(Self.self,"found", file)
        }
        
        let libmain_folder = working_dir + "libffi"
        
        let sdk = platform.get_sdk()
        let arch = platform.get_arch()
        let lib_platform = libmain_folder + "\(sdk)_\(arch)"
        
        try! lib_platform.mkpath()
        
        let include = libffi + "include"
        let lib = libffi + "lib"
        
        let include_target = include_dir()
        
        try? include_target.mkdir()
        
        try! include.move(include_target + "ffi")
        try! lib.move(lib_dir())
        //let libffi_folder = working_dir + "libffi-\(version ?? Self.default_version)"
        
        
        //let sdk = platform.get_sdk()
        //let arch = platform.get_arch()
//        try? (libffi_folder + "generate-darwin-source-and-headers.py").delete()
//        try? Path("/Users/codebuilder/Downloads/libffi-3.4.7/generate-darwin-source-and-headers.py").copy(libffi_folder + "generate-darwin-source-and-headers.py")
//        
//        try? (libffi_folder + "libffi.xcodeproj").delete()
//        try? Path("/Users/codebuilder/Downloads/libffi-3.4.7/libffi.xcodeproj").copy(libffi_folder + "libffi.xcodeproj")
//
        //try await patch(content: libffi_patch, fn: "libffi", target: libffi_folder)
        
        
        
//        try await python3_run(
//            folder: libffi_folder,
//            args: "generate-darwin-source-and-headers.py", "--only-ios"
//        )
    }
    
    public func build_library_platform(working_dir: Path) async throws {
//        let sdk = platform.get_sdk()
//        guard platform.get_arch() != .x86_64 else { return }
//        
//        let libffi_folder = working_dir + "libffi-\(version ?? Self.default_version)"
//        
//        try await xcodebuild(
//            project: libffi_folder + "libffi.xcodeproj",
//            target: "libffi-iOS",
//            root: working_dir,
//            sdk: sdk,
//            env: env(platform: platform)
//        )
    }
    
    public func post_build_library(working_dir: Path) async throws {
//        guard platform.get_arch() != .x86_64 else { return }
//        let wheels = working_dir + "wheels"
//        if !wheels.exists { try wheels.mkdir() }
//        let sdk = platform.get_sdk()
//        let libffi_folder = working_dir + "libffi-\(version ?? Self.default_version)"
//        let libffi_build = libffi_folder + "build/Release-\(sdk)"
//        
//        try libffi_build.copy(wheels + "\(sdk)")
        
        
    }
    
    public func cflag_includes() -> [Env.CFlags.Value] {
        [.include(include_dir() + "ffi")]
    }
}

extension Libffi {
//    public func pre_build(platform: any PlatformProtocol, target: Path) async throws {
//
//        switch build_target {
//        case .url(let url):
//            try await downloadTarFile(url: url, to: target)
//            //beeware_pip_download(name: <#T##String#>, output: <#T##Path#>)
//        default:
//            return
//        }
//        
//        let libffi_folder = target + "libffi-\(version ?? Self.default_version)"
//        
//        let sdk = platform.get_sdk()
//        //let arch = platform.get_arch()
//        try? (libffi_folder + "generate-darwin-source-and-headers.py").delete()
//        try? Path("/Users/codebuilder/Downloads/libffi-3.4.7/generate-darwin-source-and-headers.py").copy(libffi_folder + "generate-darwin-source-and-headers.py")
//        
//        try? (libffi_folder + "libffi.xcodeproj").delete()
//        try? Path("/Users/codebuilder/Downloads/libffi-3.4.7/libffi.xcodeproj").copy(libffi_folder + "libffi.xcodeproj")
//        
//        try await python3_run(
//            folder: libffi_folder,
//            args: "generate-darwin-source-and-headers.py", "--only-ios"
//        )
//        
//        try await xcodebuild(
//            project: libffi_folder + "libffi.xcodeproj",
//            target: "libffi-iOS",
//            root: target,
//            sdk: sdk,
//            env: env(platform: platform)
//        )
//        
//    }
//    
    public func _build_wheel(platform: any PlatformProtocol, output: Path) async throws -> Bool {
        
        
        return true
    }
}
