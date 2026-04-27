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

}

public extension MaturinWheelProtocol {
    
    /// All maturin-specific env vars. Conforming types that need to add extra vars
    /// should call this instead of `base_env()` so Rust/cargo/iOS config is preserved.
    func maturin_env() throws -> [String: String] {
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
            // cibuildwheel for iOS uses `pip --python <ios-python>` to install build deps,
            // which makes pip resolve using iOS platform tags — no binary maturin wheel exists
            // for iOS, so pip falls back to the sdist and fails to compile it.
            // Fix: pre-install maturin into the build venv (macOS pip, so it finds the binary
            // wheel) and skip build isolation so cibuildwheel uses that pre-installed maturin.
            env["CIBW_BEFORE_BUILD"] = "pip install maturin"
            env["CIBW_BUILD_FRONTEND"] = "build;args: --no-isolation"
        }
        
        return env
    }
    
    func env() throws -> [String : String] {
        try maturin_env()
    }
    
}
