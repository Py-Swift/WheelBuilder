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
            // LDFLAGS: explicitly add -lpython<ver> so the linker resolves Python symbols.
            // The Android Python's python*.pc Libs: field may contain "$(BLDLIBRARY)" (a
            // Makefile variable that pkg-config passes through unexpanded) or may simply
            // omit any -l flag entirely.  Either way meson drops the token and the linker
            // never receives -lpython3.xx, causing undefined-symbol errors under
            // -Wl,--no-undefined.  Belt-and-suspenders: add -lpython<ver> to LDFLAGS
            // directly so it is always present regardless of what the .pc file contains.
            env["CIBW_ENVIRONMENT_ANDROID"] = "NPY_DISABLE_SVML=1 LDFLAGS=\"$LDFLAGS -lpython$(python3 -c 'import sys; print(f\"{sys.version_info.major}.{sys.version_info.minor}\")')\""
            env["CIBW_CONFIG_SETTINGS_ANDROID"] = "setup-args=--cross-file=/tmp/numpy-android-meson-cross.ini setup-args=-Dblas=none setup-args=-Dlapack=none"
            // Also patch the Python .pc files so that pkg-config itself returns correct
            // link flags (belt-and-suspenders: the LDFLAGS above already covers the gap).
            // Use $PKG_CONFIG_LIBDIR which cibuildwheel sets directly to the pkgconfig dir.
            // Steps:
            //   1. Replace the unexpanded make variable $(BLDLIBRARY) with -lpython<ver>.
            //   2. If the Libs: line still has no -lpython entry (e.g. the field was simply
            //      absent), append -lpython<ver> to the Libs: line.
            env["CIBW_BEFORE_BUILD_ANDROID"] = "for f in \"$PKG_CONFIG_LIBDIR/python-3\"*.pc; do [ -f \"$f\" ] && ! [ -L \"$f\" ] || continue; VER=$(basename \"$f\" | sed 's/python-//;s/\\.pc//'); echo \"DBG: patching $f (VER=${VER})\"; grep 'Libs:' \"$f\" || true; sed -i '' \"s/\\$(BLDLIBRARY)/-lpython${VER}/g\" \"$f\"; grep -q -- -lpython \"$f\" || sed -i '' \"/^Libs:/ s/$/ -lpython${VER}/\" \"$f\"; echo \"DBG: after patch:\"; grep 'Libs:' \"$f\" || true; done"
        }
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/numpy.patch"
        ]
    }
}
