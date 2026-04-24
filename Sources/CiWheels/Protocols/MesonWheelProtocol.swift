//
//  MesonWheelProtocol.swift
//  WheelBuilder
//
import Foundation
import PlatformInfo
import PathKit
import Tools

/// Protocol for CiWheels whose build backend is meson-python.
/// Provides default Android cross-file generation and env setup.
/// Wheels only needing standard behaviour inherit this and add nothing.
public protocol MesonWheelProtocol: CiWheelProtocol {

    /// Extra INI sections appended after [host_machine] in the cross-file.
    /// Override to inject e.g. `[properties]` (numpy's longdouble_format).
    func meson_extra_ini_sections() -> String
}

public extension MesonWheelProtocol {

    var meson_cross_file_path: String {
        "/tmp/\(Self.name)-android-meson-cross.ini"
    }

    func meson_extra_ini_sections() -> String { "" }

    /// Writes the meson cross-file for the current Android target arch.
    /// Call this from `pre_build` (the default implementation calls it automatically).
    func write_meson_cross_file() throws {
        guard platform.get_sdk() == .android else { return }
        let ndk = try ndk_root().string
        let api = Process.android_api_level
        let host = Process.android_ndk_host
        let (triple, cpu): (String, String) = platform.get_arch() == .arm64
            ? ("aarch64-linux-android", "aarch64")
            : ("x86_64-linux-android", "x86_64")
        let bin = "\(ndk)/toolchains/llvm/prebuilt/\(host)/bin"
        var content = """
        [binaries]
        c = '\(bin)/\(triple)\(api)-clang'
        cpp = '\(bin)/\(triple)\(api)-clang++'
        ar = '\(bin)/llvm-ar'
        strip = '\(bin)/llvm-strip'

        [host_machine]
        system = 'android'
        cpu_family = '\(cpu)'
        cpu = '\(cpu)'
        endian = 'little'
        """
        let extra = meson_extra_ini_sections()
        if !extra.isEmpty {
            content += "\n\n" + extra
        }
        try Path(meson_cross_file_path).write(content)
    }

    // MARK: - WheelProtocol defaults

    func pre_build(target: Path) async throws {
        try write_meson_cross_file()
    }

    /// Returns the standard meson env. Call from `env()` if you need to add extras.
    func meson_env() throws -> [String: String] {
        var env = base_env()
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake ninja"
        env["CIBW_TEST_SKIP"] = "*"
        if platform.get_sdk() == .android {
            env["CIBW_CONFIG_SETTINGS_ANDROID"] = "setup-args=--cross-file=\(meson_cross_file_path)"
            // Fix python-X.Y.pc which contains unexpanded $(BLDLIBRARY) Makefile var
            env["CIBW_BEFORE_BUILD_ANDROID"] = "PYPREFIX=$(dirname \"$CMAKE_TOOLCHAIN_FILE\")/python/prefix; for f in \"$PYPREFIX/lib/pkgconfig/python-\"*.pc; do [ -f \"$f\" ] && ! [ -L \"$f\" ] || continue; VER=$(basename \"$f\" | sed 's/python-//;s/\\.pc//'); sed -i '' \"s/\\$(BLDLIBRARY)/-lpython${VER}/g\" \"$f\"; done"
        }
        return env
    }

    func env() throws -> [String: String] {
        try meson_env()
    }
}
