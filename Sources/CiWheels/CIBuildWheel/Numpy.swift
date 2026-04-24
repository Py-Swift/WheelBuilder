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
            // NPY_DISABLE_SVML=1: avoid SVML which is not available on Android.
            env["CIBW_ENVIRONMENT_ANDROID"] = "NPY_DISABLE_SVML=1"
            env["CIBW_CONFIG_SETTINGS_ANDROID"] = "setup-args=--cross-file=/tmp/numpy-android-meson-cross.ini setup-args=-Dblas=none setup-args=-Dlapack=none"
            // Android requires two fixes:
            // 1. python-3.x.pc has "$(BLDLIBRARY)" (unexpanded Makefile var) — copy the correct
            //    python-3.x-embed.pc over it so meson gets proper -lpython3.x from pkg-config.
            // 2. cibuildwheel adds -Wl,--no-undefined for Android, but meson-python strips -lpython
            //    from extension link lines. Inject -L<prefix>/lib -lpython3.x via [built-in options]
            //    in the cross file so every extension .so links the Python symbols explicitly.
            // CMAKE_TOOLCHAIN_FILE is set by cibuildwheel for every Android build and its dirname
            // is the per-target temp dir; Python is always at dirname/python/prefix.
            env["CIBW_BEFORE_BUILD_ANDROID"] = "PYPREFIX=$(dirname \"$CMAKE_TOOLCHAIN_FILE\")/python/prefix; PYLIBDIR=\"$PYPREFIX/lib\"; PCDIR=\"$PYLIBDIR/pkgconfig\"; PC=$(ls \"$PCDIR/python-3.\"*\"-embed.pc\" 2>/dev/null | head -1); if [ -n \"$PC\" ]; then VER=$(basename \"$PC\" | sed 's/python-//;s/-embed\\.pc//'); BROKEN=\"$PCDIR/python-${VER}.pc\"; [ -f \"$BROKEN\" ] && cp \"$PC\" \"$BROKEN\"; { echo ''; echo '[built-in options]'; echo \"c_link_args = ['-L${PYLIBDIR}', '-lpython${VER}']\"; echo \"cpp_link_args = ['-L${PYLIBDIR}', '-lpython${VER}']\"; } >> /tmp/numpy-android-meson-cross.ini; fi"
        }
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/numpy.patch"
        ]
    }
}
