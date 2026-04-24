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
            //   python-3.x.pc       Libs: -L${libdir} $(BLDLIBRARY)   <- broken: $(BLDLIBRARY) is an
            //                                                              unexpanded Makefile variable;
            //                                                              pkg-config passes it through
            //                                                              literally so the linker never
            //                                                              receives -lpython3.x.
            //   python-3.x-embed.pc Libs: -L${libdir} -lpython3.x     <- correct
            //   Fix: copy the embed .pc over the broken one so meson's dependency('python-3.x') lookup
            //   returns correct -L and -l flags.
            //
            // Problem 2 — meson deliberately strips -lpython from Python-extension link lines:
            //   meson-python's python.extension_module() does NOT add -lpython3.x to the link because
            //   on typical Linux/macOS the extension is dlopen'd into the interpreter and all Python
            //   symbols are resolved from the already-loaded libpython. But Android's cibuildwheel
            //   forces -Wl,--no-undefined on every shared object, so each extension .so MUST resolve
            //   PyMem_Malloc / PyErr_* / etc. at link time — failing with dozens of
            //   "undefined symbol: Py..." errors (observed on CI run 24879792715).
            //   Fix: inject both -L<prefix>/lib and -lpython3.x via the meson cross file's
            //   [built-in options] c_link_args / cpp_link_args.  BOTH are needed:
            //   - -l alone → meson's sin/-lm capability probe fails ("unable to find library
            //     -lpython3.x") because the probe runs without a -L path.
            //   - -L alone → extensions still missing the explicit -l → undefined Py* symbols.
            //
            // NOTE on PKG_CONFIG_LIBDIR: this env var is NOT reliably set during before_build
            // (confirmed empty in CI run 24880758596). We use `python -c "import sys; print(sys.prefix)"`
            // instead — `python` in the before_build env is the cross-target Python whose prefix is the
            // Chaquopy/PBS sysroot, so prefix/lib is always the correct library directory.
            // NOTE: PKG_CONFIG_LIBDIR is NOT reliable — it may point to the NDK sysroot pkgconfig
            // rather than Python's. LDFLAGS is reliably set by cibuildwheel to include
            // -L<python_prefix>/lib for Android builds, so we derive PYLIBDIR from that.
            env["CIBW_BEFORE_BUILD_ANDROID"] = "set -e; PYLIBDIR=$(echo \"$LDFLAGS\" | tr ' ' '\\n' | grep '^-L' | head -1 | sed 's/^-L//'); PCDIR=\"${PYLIBDIR}/pkgconfig\"; echo \"DBG PYLIBDIR=$PYLIBDIR\"; echo \"DBG PCDIR=$PCDIR\"; ls \"$PCDIR/\" 2>&1; PC=$(ls \"$PCDIR/python-3.\"*\"-embed.pc\" 2>/dev/null | head -1); if [ -z \"$PC\" ]; then echo \"ERROR: python-*-embed.pc not found in $PCDIR\"; exit 1; fi; VER=$(basename \"$PC\" | sed 's/python-//;s/-embed\\.pc//'); BROKEN=\"$PCDIR/python-${VER}.pc\"; [ -f \"$BROKEN\" ] && cp \"$PC\" \"$BROKEN\" && echo \"DBG: copied embed->pc, Libs now: $(grep Libs: $BROKEN)\"; echo \"DBG libpython: $(ls ${PYLIBDIR}/libpython${VER}*.so ${PYLIBDIR}/libpython${VER}*.a 2>/dev/null | head -1)\"; { echo \"\"; echo \"[built-in options]\"; echo \"c_link_args = ['-L${PYLIBDIR}', '-lpython${VER}']\"; echo \"cpp_link_args = ['-L${PYLIBDIR}', '-lpython${VER}']\"; } >> /tmp/numpy-android-meson-cross.ini; echo \"DBG cross file:\"; cat /tmp/numpy-android-meson-cross.ini"
        }
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/numpy.patch"
        ]
    }
}
