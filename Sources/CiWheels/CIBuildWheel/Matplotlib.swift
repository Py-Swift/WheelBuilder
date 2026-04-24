//
//  Matplotlib.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation


@WheelClass
public final class Matplotlib: CiWheelProtocol {

    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake ninja"
        env["CIBW_TEST_SKIP"] = "*"
        if platform.get_sdk() == .android {
            // p4a: need_stl_shared=True, CXXFLAGS += -Wno-c++11-narrowing
            env["CIBW_ENVIRONMENT_ANDROID"] = "CXXFLAGS=\"$CXXFLAGS -Wno-c++11-narrowing\""
            env["CIBW_CONFIG_SETTINGS_ANDROID"] = "setup-args=--cross-file=/tmp/matplotlib-android-meson-cross.ini"
            env["CIBW_BEFORE_BUILD_ANDROID"] = "PYPREFIX=$(dirname \"$CMAKE_TOOLCHAIN_FILE\")/python/prefix; for f in \"$PYPREFIX/lib/pkgconfig/python-\"*.pc; do [ -f \"$f\" ] && ! [ -L \"$f\" ] || continue; VER=$(basename \"$f\" | sed 's/python-//;s/\\.pc//'); sed -i '' \"s/\\$(BLDLIBRARY)/-lpython${VER}/g\" \"$f\"; done"
        }
        return env
    }

    public func pre_build(target: Path) async throws {
        // replace "meson-python>=0.13.1,!=0.17.*" with "meson-python>=0.13.1"
        let pyproject = target + "pyproject.toml"
        var contents = try String(contentsOf: pyproject.url)
        contents = contents.replacingOccurrences(of: "meson-python>=0.13.1,<0.17.0", with: "meson-python>=0.13.1")
        try contents.write(to: pyproject.url, atomically: true, encoding: .utf8)

        guard platform.get_sdk() == .android else { return }
        let ndk = try ndk_root().string
        let api = Process.android_api_level
        let host = Process.android_ndk_host
        let (triple, cpu): (String, String) = platform.get_arch() == .arm64
            ? ("aarch64-linux-android", "aarch64")
            : ("x86_64-linux-android", "x86_64")
        let bin = "\(ndk)/toolchains/llvm/prebuilt/\(host)/bin"
        let content = """
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
        try Path("/tmp/matplotlib-android-meson-cross.ini").write(content)
    }
    
    public func patches() -> [URL] {
        [
            //"https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/matplotlib.patch"
        ]
    }
}

