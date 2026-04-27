//
//  Numpy.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation

@WheelClass
public final class Numpy: MesonWheelProtocol {

    // numpy needs longdouble_format in the cross-file [properties] section
    public func meson_extra_ini_sections() -> String {
        let longdouble_format = platform.get_arch() == .arm64
            ? "IEEE_QUAD_LE"          // aarch64-linux: 128-bit quad
            : "INTEL_EXTENDED_16_BYTES_LE" // x86_64-linux: 80-bit in 16 bytes
        return """
        [properties]
        longdouble_format = '\(longdouble_format)'
        """
    }

    public func env() throws -> [String : String] {
        var env = try meson_env()
        env["CIBW_BEFORE_BUILD"] = ""
        if platform.get_sdk() == .android {
            env["CIBW_ENVIRONMENT_ANDROID"] = "NPY_DISABLE_SVML=1 PKG_CONFIG_PATH=\"\""
            env["CIBW_CONFIG_SETTINGS_ANDROID"] = "setup-args=--cross-file=\(meson_cross_file_path) setup-args=-Dblas=none setup-args=-Dlapack=none"
            // Android requires two fixes:
            // 1. python-3.x.pc has "$(BLDLIBRARY)" (unexpanded Makefile var) — copy the
            //    python-3.x-embed.pc over it so meson gets proper -lpython3.x from pkg-config.
            // 2. cibuildwheel adds -Wl,--no-undefined for Android, but meson-python strips
            //    -lpython from extension link lines. Inject via [built-in options] in cross-file.
            // NOTE: strip any existing [built-in options] section before appending so that
            // a second arch target (cp314, …) doesn't get a duplicate section.
            env["CIBW_BEFORE_BUILD_ANDROID"] = "PYPREFIX=$(dirname \"$CMAKE_TOOLCHAIN_FILE\")/python/prefix; PYLIBDIR=\"$PYPREFIX/lib\"; PCDIR=\"$PYLIBDIR/pkgconfig\"; PC=$(ls \"$PCDIR/python-3.\"*\"-embed.pc\" 2>/dev/null | head -1); if [ -n \"$PC\" ]; then VER=$(basename \"$PC\" | sed 's/python-//;s/-embed\\.pc//'); BROKEN=\"$PCDIR/python-${VER}.pc\"; [ -f \"$BROKEN\" ] && cp \"$PC\" \"$BROKEN\"; sed -i '' '/^\\[built-in options\\]/,$d' \(meson_cross_file_path); { echo ''; echo '[built-in options]'; echo \"c_link_args = ['-L${PYLIBDIR}', '-lpython${VER}']\"; echo \"cpp_link_args = ['-L${PYLIBDIR}', '-lpython${VER}']\"; } >> \(meson_cross_file_path); fi"
        }
        return env
    }

    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/numpy.patch"
        ]
    }
}
