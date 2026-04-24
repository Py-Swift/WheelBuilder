//
//  Pydantic_core.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Pydantic_core: CiWheelProtocol {

    public func env() throws -> [String : String] {
        var env = base_env()
        
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            env["CARGO"] = "\(home)/.cargo/bin/cargo"
            env["RUSTC"] = "\(home)/.cargo/bin/rustc"
        }
        
        if platform.get_sdk() == .android {
            // Set macOS SDK so Rust host build scripts (proc-macro2, quote, etc.)
            // can find libSystem when cross-compiling for Android
            env["SDKROOT"] = try Process.get_macos_sdk().string
        } else {
            env["CIBW_XBUILD_TOOLS_IOS"] = "cmake rustc cargo"
            
            let ios_sdkroot = try platform.sdk_root()
            
            let cargo_target = [
                "-C link-arg=-isysroot", "-C link-arg=\(ios_sdkroot)",
                "-C link-arg=-arch", "-C link-arg=\(platform.get_arch())",
                "-C link-arg=-undefined", "-C link-arg=dynamic_lookup"
            ]
            
            env["OSX_SDKROOT"] = try Process.get_macos_sdk().string
            env["IOS_SDKROOT"] = ios_sdkroot.string
            env["SDKROOT"] = ios_sdkroot.string
            env[platform.cargo_target_key] = cargo_target.joined(separator: " ")
        }
        
        return env
    }
}


