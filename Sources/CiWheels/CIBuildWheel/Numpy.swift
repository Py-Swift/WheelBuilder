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
            // Android Python build: two independent problems must be solved so numpy links.
            //
            // Problem 1 — broken pkg-config file in Chaquopy sysroot:
            //   python-3.x.pc       Libs: -L${libdir} $(BLDLIBRARY)   <- $(BLDLIBRARY) is an
            //                                                              unexpanded Makefile var;
            //                                                              pkg-config passes it through
            //                                                              literally so downstream tools
            //                                                              never see -lpython3.x.
            //   python-3.x-embed.pc Libs: -L${libdir} -lpython3.x     <- correct
            //   Fix: copy the embed .pc over the broken one so meson's pkg-config lookup for
            //   dependency('python-3.x') returns a sane -L path (used for probes and extensions).
            //
            // Problem 2 — meson deliberately strips -lpython from Python-extension link lines:
            //   meson-python's python.extension_module() does NOT pass -lpython3.x because on typical
            //   Linux/macOS hosts the extension is dlopen'd into the interpreter and all Python symbols
            //   are resolved from the already-loaded libpython.  But Android's cibuildwheel config
            //   forces -Wl,--no-undefined on every shared object, so the extension .so MUST resolve
            //   PyMem_Malloc / PyErr_* / etc. at link time — otherwise the link fails with dozens of
            //   "undefined symbol: Py..." errors (observed on run 24879792715).
            //   Fix: inject both -L<prefix>/lib and -lpython3.x via the meson cross file's
            //   [built-in options] c_link_args / cpp_link_args.  Both are required: the bare -l alone
            //   breaks meson's sin/-lm probe (it runs without the Python -L path and reports
            //   "unable to find library -lpython3.x"), as seen on run 24877608829.
            //
            //   <prefix>/lib is $(dirname $PKG_CONFIG_LIBDIR) because cibuildwheel sets
            //   PKG_CONFIG_LIBDIR=$prefix/lib/pkgconfig in android-env.sh.
            env["CIBW_BEFORE_BUILD_ANDROID"] = "set -e; PCDIR=\"$PKG_CONFIG_LIBDIR\"; PYLIBDIR=\"$(dirname \"$PCDIR\")\"; echo \"DBG PCDIR=$PCDIR\"; echo \"DBG PYLIBDIR=$PYLIBDIR\"; ls \"$PCDIR/\" 2>&1; PC=$(ls \"$PCDIR/python-3.\"*\"-embed.pc\" 2>/dev/null | head -1); if [ -z \"$PC\" ]; then echo \"ERROR: python-*-embed.pc not found in $PCDIR\"; exit 1; fi; VER=$(basename \"$PC\" | sed 's/python-//;s/-embed\\.pc//'); BROKEN=\"$PCDIR/python-${VER}.pc\"; [ -f \"$BROKEN\" ] && cp \"$PC\" \"$BROKEN\" && echo \"DBG: copied embed->pc, Libs now: $(grep Libs: $BROKEN)\"; LIBPY=\"$(ls $PYLIBDIR/libpython${VER}*.so $PYLIBDIR/libpython${VER}*.a 2>/dev/null | head -1)\"; echo \"DBG libpython on disk: $LIBPY\"; { echo \"\"; echo \"[built-in options]\"; echo \"c_link_args = ['-L${PYLIBDIR}', '-lpython${VER}']\"; echo \"cpp_link_args = ['-L${PYLIBDIR}', '-lpython${VER}']\"; } >> /tmp/numpy-android-meson-cross.ini; echo \"DBG cross file:\"; cat /tmp/numpy-android-meson-cross.ini"
        }
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/numpy.patch"
        ]
    }
}
