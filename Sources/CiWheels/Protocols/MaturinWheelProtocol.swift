//
//  MaturinWheelProtocol.swift
//  WheelBuilder
//
import Foundation
import PlatformInfo
import Tools
import PathKit

public protocol MaturinWheelProtocol: CiWheelProtocol {
    
}


func maturin_build(src: Path, target: String, wheels: Path, env: [String:String]) async throws {
    let proc = Process()
    proc.executablePath = .maturin
    
    proc.arguments = [
        "build", "--release", "--target", target, "--out", wheels.string,  "-v"
    ]
    
    proc.currentDirectoryURL = src.url
    
    proc.environment = env
    
    try proc.run()
    
    proc.waitUntilExit()
}

extension PlatformProtocol {
    var cargo_target_key: String {
        switch Self.sdk {
            
        case .iphoneos:
            "CARGO_TARGET_AARCH64_APPLE_IOS_RUSTFLAGS"
        case .iphonesimulator:
            switch Self.arch {
            case .arm64: "CARGO_TARGET_AARCH64_APPLE_IOS_SIM_RUSTFLAGS"
            case .x86_64: "CARGO_TARGET_X86_64_APPLE_IOS_RUSTFLAGS"
            }
        case .macos:
            fatalError()
        case .android:
            switch Self.arch {
            case .arm64: "CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER"
            case .x86_64: "CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER"
            }
        }
    }
    
    var maturin_target: String {
        switch Self.sdk {
            
        case .iphoneos:
            "aarch64-apple-ios"
        case .iphonesimulator:
            switch Self.arch {
            case .arm64: "aarch64-apple-ios-sim"
            case .x86_64: "x86_64-apple-ios"
            }
        case .macos:
            fatalError()
        case .android:
            // Rust target triples do NOT include the API level
            switch Self.arch {
            case .arm64: "aarch64-linux-android"
            case .x86_64: "x86_64-linux-android"
            }
        }
    }
    
    func get_arch() -> Arch { Self.arch }
    
    func get_sdk() -> SDK { Self.sdk }
    
    func sdk_root() throws -> Path {
        try Process.get_sdk(sdk: Self.sdk)
    }

    func py_maturin_framework(cached: CachedPython) -> Path {
        switch Self.sdk {
            
        case .iphoneos:
            cached.arm64
        case .iphonesimulator:
            switch Self.arch {
            case .arm64: cached.arm64_simulator
            case .x86_64: cached.x86_64_simulator
            }
        case .macos:
            fatalError()
        case .android:
            switch Self.arch {
            case .arm64: cached.arm64_android
            case .x86_64: cached.x86_64_android
            }
        }
    }
}

public extension MaturinWheelProtocol {
    
    func env() throws -> [String : String] {
        var env = base_env() + ProcessInfo.processInfo.environment
        
        env["PATH"]?.extendedPath() 
        
        return env
    }
    
    func fix_wheel_name(root: Path, fn: String, subfix: String) throws {
        if let result = try root.children().first(where: {$0.lastComponent.hasSuffix(subfix)}) {
            try result.move(root + fn)
        }
    }
    
    func build_wheel(target: Path, py_cache: CachedPython, output: Path, subfix: String) async throws {
        var env = try env()
        
        switch platform.get_sdk() {
        case .android:
            // Mirrors p4a RustCompiledComponentsRecipe.get_recipe_env()
            let ndk = try ndk_root()
            let llvm_bin = ndk + "toolchains/llvm/prebuilt/\(Process.android_ndk_host)/bin"
            let sysroot = try platform.sdk_root()
            let api = Process.android_api_level
            
            let clang: String
            let libDir: String
            switch platform.get_arch() {
            case .arm64:
                clang = (llvm_bin + "aarch64-linux-android\(api)-clang").string
                libDir = (sysroot + "usr/lib/aarch64-linux-android/\(api)").string
            case .x86_64:
                clang = (llvm_bin + "x86_64-linux-android\(api)-clang").string
                libDir = (sysroot + "usr/lib/x86_64-linux-android/\(api)").string
            }
            
            env["ANDROID_NDK_HOME"] = ndk.string
            env["PYO3_CROSS_PYTHON_VERSION"] = py_cache.version
            env["PYO3_CROSS_LIB_DIR"] = platform.py_maturin_framework(cached: py_cache).string
            // CARGO_TARGET_*_LINKER = clang binary (p4a: cargo_linker_name)
            env[platform.cargo_target_key] = clang
            // RUSTFLAGS with lib search path (p4a: RUSTFLAGS = "-Clink-args=-L{libs}")  
            env["RUSTFLAGS"] = "-Clink-args=-L\(libDir)"
            
        default:
            let ios_sdkroot = try platform.sdk_root()
            
            let cargo_target = [
                "-C link-arg=-isysroot", "-C link-arg=\(ios_sdkroot)",
                "-C link-arg=-arch", "-C link-arg=\(platform.get_arch())",
                "-C link-arg=-L", "-C link-arg=\(py_cache.python)",
                "-C link-arg=-undefined", "-C link-arg=dynamic_lookup"
            ]
            
            env["OSX_SDKROOT"] = try Process.get_macos_sdk().string
            env["IOS_SDKROOT"] = ios_sdkroot.string
            env["PYTHONDIR"] = py_cache.python.string
            env["PYO3_CROSS_PYTHON_VERSION"] = py_cache.version
            env["SDKROOT"] = ios_sdkroot.string
            env["PYO3_CROSS_LIB_DIR"] = platform.py_maturin_framework(cached: py_cache).string
            //env["OPENSSL_DIR"] = "/usr/local/Cellar/openssl@3/3.5.2"
            env[platform.cargo_target_key] = cargo_target.joined(separator: " ")
        }
        
        switch build_target {
        case .local(_):
            break
        case .pypi(let pypi):
            if let pypi_folder = try pip_download(name: pypi, version: version, output: target) {
                
                try await maturin_build(src: pypi_folder, target: platform.maturin_target, wheels: output, env: env)
                try fix_wheel_name(root: output, fn: "\(pypi_folder.lastComponent)-cp313-cp313-\(platform.wheel_file_platform).whl", subfix: subfix)
            }
        case .url(_):
            break
        }
        
        
    }
    
    func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        []
    }
}
