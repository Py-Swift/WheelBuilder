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
            // The Android Python sysroot ships two pkg-config files:
            //   python-3.x.pc       Libs: -L${libdir} $(BLDLIBRARY)   <- broken: $(BLDLIBRARY) is
            //                                                              an unexpanded Makefile var;
            //                                                              pkg-config passes it through
            //                                                              literally so the linker never
            //                                                              receives -lpython3.x, causing
            //                                                              undefined-symbol errors under
            //                                                              -Wl,--no-undefined.
            //   python-3.x-embed.pc Libs: -L${libdir} -lpython3.x     <- correct
            //
            // Fix: copy the embed .pc over the broken one so pkg-config returns correct link flags.
            // NOTE: Do NOT also add c_link_args to the meson cross file.  Adding -lpython3.x to
            // [built-in options] c_link_args without the matching -L path injects a dangling -l flag
            // into every meson linker check (including the sin/-lm probe), causing them all to fail
            // with "unable to find library -lpython3.x" and aborting the configure phase.
            env["CIBW_BEFORE_BUILD_ANDROID"] = "PCDIR=\"$PKG_CONFIG_LIBDIR\"; echo \"DBG PCDIR=$PCDIR\"; ls \"$PCDIR/\" 2>&1; PC=$(ls \"$PCDIR/python-3.\"*\"-embed.pc\" 2>/dev/null | head -1); if [ -n \"$PC\" ]; then VER=$(basename \"$PC\" | sed 's/python-//;s/-embed\\.pc//'); BROKEN=\"$PCDIR/python-${VER}.pc\"; [ -f \"$BROKEN\" ] && cp \"$PC\" \"$BROKEN\" && echo \"DBG: copied embed->pc, Libs now: $(grep Libs: $BROKEN)\"; else echo \"DBG: WARNING python-*-embed.pc not found in $PCDIR\"; fi"
        }
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/numpy.patch"
        ]
    }
}
