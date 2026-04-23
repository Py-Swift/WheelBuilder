//
//  Untitled.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation

@WheelClass
public final class Numpy: CiWheelProtocol {
    
    public func pre_build(target: Path) async throws {
        guard platform.get_sdk() == .android else { return }
        let ndk = try ndk_root().string
        let api = Process.android_api_level
        let host = Process.android_ndk_host
        let (triple, cpu): (String, String) = platform.get_arch() == .arm64
            ? ("aarch64-linux-android", "aarch64")
            : ("x86_64-linux-android", "x86_64")
        let bin = "\(ndk)/toolchains/llvm/prebuilt/\(host)/bin"
        // longdouble_format: aarch64-linux = IEEE_QUAD_LE (128-bit), x86_64-linux = INTEL_EXTENDED_16_BYTES_LE (80-bit in 16)
        let longdouble_format = platform.get_arch() == .arm64 ? "IEEE_QUAD_LE" : "INTEL_EXTENDED_16_BYTES_LE"
        let content = """
        [binaries]
        c = '\(bin)/\(triple)\(api)-clang'
        cpp = '\(bin)/\(triple)\(api)-clang++'
        ar = '\(bin)/llvm-ar'
        strip = '\(bin)/llvm-strip'

        [properties]
        longdouble_format = '\(longdouble_format)'

        [host_machine]
        system = 'android'
        cpu_family = '\(cpu)'
        cpu = '\(cpu)'
        endian = 'little'
        """
        try Path("/tmp/numpy-android-meson-cross.ini").write(content)
    }

    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_BEFORE_BUILD"] = ""
        env["CIBW_TEST_SKIP"] = "*"
        if platform.get_sdk() == .android {
            env["CIBW_ENVIRONMENT_ANDROID"] = "NPY_DISABLE_SVML=1"
            env["CIBW_CONFIG_SETTINGS_ANDROID"] = "setup-args=--cross-file=/tmp/numpy-android-meson-cross.ini setup-args=-Dblas=none setup-args=-Dlapack=none"
            // The Android Python's python*.pc files contain a literal "$(BLDLIBRARY)" which
            // pkg-config passes unchanged to the linker, causing clang to fail looking for
            // a file named "$(BLDLIBRARY)". Patch the .pc files before meson reads them.
            // Find the Python prefix from CFLAGS (contains -I/.../python/prefix/include).
            env["CIBW_BEFORE_BUILD_ANDROID"] = "echo \"DBG CMAKE_TOOLCHAIN_FILE=$CMAKE_TOOLCHAIN_FILE\"; PYPREFIX=$(dirname \"$CMAKE_TOOLCHAIN_FILE\")/python/prefix; echo \"DBG PYPREFIX=$PYPREFIX\"; ls \"$PYPREFIX/lib/pkgconfig/\" 2>&1 || echo \"DBG: pkgconfig dir not found\"; for f in \"$PYPREFIX/lib/pkgconfig/python-\"*.pc; do [ -f \"$f\" ] && ! [ -L \"$f\" ] || continue; echo \"DBG: patching $f\"; VER=$(basename \"$f\" | sed 's/python-//;s/\\.pc//'); sed -i '' \"s/\\$(BLDLIBRARY)/-lpython${VER}/g\" \"$f\"; echo \"DBG: patched -lpython${VER}\"; done"
        }
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/numpy.patch"
        ]
    }
}
