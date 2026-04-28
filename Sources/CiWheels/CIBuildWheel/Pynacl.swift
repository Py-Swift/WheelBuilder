//
//  Pynacl.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation

@WheelClass
public final class Pynacl: CiWheelProtocol {

    public func env() throws -> [String : String] {
        var env = base_env()
        if platform.get_sdk() == .android {
            // SODIUM_INSTALL=bundled: pynacl compiles its vendored libsodium
            // amalgamation directly via CC (set to Android cross-compiler by
            // cibuildwheel). No autoconf needed — works with NDK clang.
            // PKG_CONFIG_PATH="": prevents macOS Python pkgconfig from shadowing
            // the Android Python pkgconfig set via PKG_CONFIG_LIBDIR.
            env["CIBW_ENVIRONMENT_ANDROID"] = "SODIUM_INSTALL=\"bundled\" PKG_CONFIG_PATH=\"\""
        }
        return env
    }
}
