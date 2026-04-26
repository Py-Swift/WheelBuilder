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
        var env = base_env()
        
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            env["CARGO"] = "\(home)/.cargo/bin/cargo"
            env["RUSTC"] = "\(home)/.cargo/bin/rustc"
            // Prepend ~/.cargo/bin so cibuildwheel's shutil.which("cargo") finds the rustup
            // shim (which has iOS targets installed) before Homebrew's cargo at /usr/local/bin.
            if let currentPath = env["PATH"] {
                env["PATH"] = "\(home)/.cargo/bin:\(currentPath)"
            }
        }
        
        if platform.get_sdk() == .android {
            // Set macOS SDK so Rust host build scripts (proc-macro2, quote, etc.)
            // can find libSystem when cross-compiling for Android
            env["SDKROOT"] = try Process.get_macos_sdk().string
        } else {
            let ios_sdkroot = try platform.sdk_root()
            let macos_sdkroot = try Process.get_macos_sdk()
            
            env["CIBW_XBUILD_TOOLS_IOS"] = "cmake rustc cargo maturin"
            
            let cargo_target = [
                "-C link-arg=-isysroot", "-C link-arg=\(ios_sdkroot)",
                "-C link-arg=-arch", "-C link-arg=\(platform.get_arch())",
                "-C link-arg=-undefined", "-C link-arg=dynamic_lookup"
            ]
            
            env["OSX_SDKROOT"] = macos_sdkroot.string
            env["IOS_SDKROOT"] = ios_sdkroot.string
            // Use macOS SDKROOT in the outer env so host tools (pip, cargo build
            // scripts like proc-macro2) don't fail on iPhoneOS SDK headers.
            // The iOS SDKROOT is passed into the cibuildwheel build env below.
            env["SDKROOT"] = macos_sdkroot.string
            env[platform.cargo_target_key] = cargo_target.joined(separator: " ")
            // Force explicit --target so maturin uses full triple comparison for
            // cross_compiling detection (rustc host x86_64-apple-darwin != aarch64-apple-ios)
            // rather than machine-arch comparison which fails on Apple Silicon for iOS device.
            env["MATURIN_PEP517_ARGS"] = "--target \(platform.maturin_target)"
            env["CIBW_ENVIRONMENT_IOS"] = [
                "PYO3_CROSS=1",
                "IOS_SDKROOT=\"\(ios_sdkroot)\"",
                #"PYO3_CROSS_PYTHON_VERSION=$(python3 -c 'import sys; v=sys.version_info; print(f"{v.major}.{v.minor}")')"#
            ].joined(separator: " ")
        }
        
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
            
            // Compute ext_suffix for the pyo3 config file.
            // e.g. "3.13" → versionTag = "313"
            let versionParts = py_cache.version.split(separator: ".").compactMap { Int($0) }
            let versionTag = versionParts.count >= 2 ? "\(versionParts[0])\(versionParts[1])" : "313"
            let extSuffix = platform.get_sdk() == .iphoneos
                ? ".cpython-\(versionTag)-iphoneos.so"
                : ".cpython-\(versionTag)-iphonesimulator.so"
            
            // Write a pyo3 config file so maturin skips Python interpreter discovery.
            // Without this, maturin calls `python3` which returns "darwin" for platform.system(),
            // and fails because that doesn't match any iOS target (cross_compiling: false for all iOS).
            let pyo3ConfigContent = [
                "implementation=CPython",
                "version=\(py_cache.version)",
                "shared=true",
                "abi3=false",
                "build_flags=",
                "suppress_build_script_link_lines=false",
                "lib_name=python\(py_cache.version)",
                "pointer_width=64",
                "ext_suffix=\(extSuffix)",
            ].joined(separator: "\n")
            let pyo3ConfigPath = "/tmp/pyo3_config_\(platform.maturin_target.replacingOccurrences(of: "-", with: "_")).txt"
            try pyo3ConfigContent.write(toFile: pyo3ConfigPath, atomically: true, encoding: .utf8)
            env["PYO3_CONFIG_FILE"] = pyo3ConfigPath
            
            env["OSX_SDKROOT"] = try Process.get_macos_sdk().string
            env["IOS_SDKROOT"] = ios_sdkroot.string
            env["PYTHONDIR"] = py_cache.python.string
            env["PYO3_CROSS_PYTHON_VERSION"] = py_cache.version
            env["SDKROOT"] = ios_sdkroot.string
            env["PYO3_CROSS_LIB_DIR"] = platform.py_maturin_framework(cached: py_cache).string
            env[platform.cargo_target_key] = cargo_target.joined(separator: " ")
        }
        
        switch build_target {
        case .local(_):
            break
        case .pypi(let pypi):
            if let pypi_folder = try pip_download(name: pypi, version: version, output: target) {
                
                try await maturin_build(src: pypi_folder, target: platform.maturin_target, wheels: output, env: env)
                // iOS: maturin already outputs the correct ios_13_0_arch_sdk wheel name.
                // fix_wheel_name (host-arch suffix search) is only needed for Android.
                if platform.get_sdk() == .android {
                    try fix_wheel_name(root: output, fn: "\(pypi_folder.lastComponent)-cp313-cp313-\(platform.wheel_file_platform).whl", subfix: subfix)
                }
            }
        case .url(_):
            break
        }
        
        
    }
    
    func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        []
    }
}
