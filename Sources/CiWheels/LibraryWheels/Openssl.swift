//
//  Openssl.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation


public final class Openssl: LibraryWheelProtocol {
    
    public static let name: String = "openssl"
    
    static var default_version: String = "3.0.17-1"
    
    public var version: String?
    
    //public var output: Path
    public var root: Path
    
    public var build_target: BuildTarget {
        let v = version ?? Self.default_version
        return .url(
            //"https://github.com/libffi/libffi/releases/download/v\(v)/libffi-\(v).tar.gz"
            //"https://github.com/beeware/cpython-apple-source-deps/releases/download/libFFI-\(v)/libffi-\(v)-\(sdk).\(arch).tar.gz",
            "https://github.com/beeware/cpython-apple-source-deps/releases/download/OpenSSL-\(v)/openssl-\(v)-\(platform.sdk).\(platform.arch).tar.gz"
        )
    }
    
    public var platform: any PlatformProtocol
    
    init(version: String? = nil, platform: any PlatformProtocol, root: Path) {
        self.version = version
        self.platform = platform
        self.root = root + Self.name
    }
    
    public static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self {
        .init(version: version, platform: platform, root: root)
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
        let openssl: Path = working_dir //+ "libffi-\(version ?? Self.default_version)"
        
        //print(try working_dir.children())
        //fatalError("\(try! working_dir.children())")
        let openssl_folder = working_dir + "openssl"
        
        let sdk = platform.get_sdk()
        let arch = platform.get_arch()
        let lib_platform = openssl_folder + "\(sdk)_\(arch)"
        
        try? lib_platform.mkpath()
        
        let include = openssl + "include"
        let lib = openssl + "lib"
        
        let include_target = include_dir()
        
        try? include_target.mkdir()
        
        try (include + "openssl").copy(include_target + "openssl")
        try lib.move(lib_dir())
        //let libffi_folder = working_dir + "libffi-\(version ?? Self.default_version)"
        //print(try include_target.map(\.self))
        //fatalError()
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

