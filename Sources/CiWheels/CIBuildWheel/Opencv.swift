//
//  Opencv.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation
import Tools
import Platforms

@WheelClass(build_target: .url("https://github.com/opencv/opencv-python/archive/refs/tags/92.tar.gz"))
public final class Opencv: CiWheelProtocol {
    
    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_ENVIRONMENT_IOS"] = [
            "PIP_EXTRA_INDEX_URL=\"https://pypi.anaconda.org/pyswift/simple\"",
            "CI_BUILD=\"1\"",
            "OPENCV_PYTHON_SKIP_GIT_COMMANDS=\"1\"",
            "CMAKE_ARGS=\"-DCMAKE_OSX_SYSROOT=$(xcrun --sdk \(platform.sdk) --show-sdk-path)\""
        ].joined(separator: " ")
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake ninja"
        if platform.get_sdk() == .android {
            env["CIBW_ENVIRONMENT_ANDROID"] = [
                "OPENCV_PYTHON_SKIP_GIT_COMMANDS=\"1\"",
                "CI_BUILD=\"1\"",
                "PKG_CONFIG_PATH=\"\""
            ].joined(separator: " ")
            // Patches for Android cross-compilation:
            //
            // 1. ctypes dlopen fix: PBS Android Python's ctypes/__init__.py does
            //    dlopen(libpython3.x.so) — an Android ELF that can't load on macOS.
            //    Create a dummy macOS dylib at the expected path so dlopen succeeds.
            //
            // 2. setup.py Android block — mirrors the iOS block the iOS patch adds.
            //    The iOS patch appends -DPYTHON3INTERP_FOUND=ON and
            //    -DPYTHON3_INCLUDE_PATH=... as cmake_args in setup.py. Those become
            //    cmake command-line -D overrides which cmake cannot overwrite via
            //    cmake code (unlike -C preload cache entries or cmake set() calls).
            //    BEFORE_BUILD writes a Python patcher to /tmp via heredoc and runs it.
            //
            // 3. Android sample APKs need Gradle + Java — not on the CI runner.
            //    Remove add_subdirectory(android) from opencv/samples/CMakeLists.txt.
            env["CIBW_BEFORE_BUILD_ANDROID"] = #"""
                set -e
                OCV="${GITHUB_WORKSPACE}/output/wheels/opencv-python-92"
                PYVER=$(python -c "import sys; v=sys.version_info; print(f'{v.major}.{v.minor}')")
                PBS_LIB=$(python -c "import sys,os; print(os.path.join(os.path.dirname(sys.prefix), 'pbs', 'python', 'lib'))")
                mkdir -p "$PBS_LIB"
                printf 'void _dummy(void){}' | cc -x c - -dynamiclib -o "$PBS_LIB/libpython${PYVER}.so" 2>/dev/null || true
                rm -rf "${OCV}/_skbuild" 2>/dev/null || true
                cat > /tmp/wb_android_patch.py << 'PYEOF'
                import sys, os
                f = os.environ["GITHUB_WORKSPACE"] + "/output/wheels/opencv-python-92/setup.py"
                src = open(f).read()
                if "is_android" in src:
                    print("[WheelBuilder] setup.py already patched for Android")
                    sys.exit(0)
                src = src.replace(
                    '    is_ios = "ios" in target_platform',
                    '    is_ios = "ios" in target_platform\n    is_android = "android" in target_platform')
                block = (
                    "\n    if is_android:\n"
                    "        _inc = __import__('sysconfig').get_path('include')\n"
                    "        cmake_args.append('-DPYTHON3INTERP_FOUND=ON')\n"
                    "        cmake_args.append('-DPYTHON3_INCLUDE_PATH=%s' % _inc)\n"
                    "        cmake_args.append('-DPYTHON3_VERSION_STRING=%d.%d' % (sys.version_info.major, sys.version_info.minor))\n"
                    "        cmake_args.append('-DPYTHON3_VERSION_MAJOR=%d' % sys.version_info.major)\n"
                    "        cmake_args.append('-DPYTHON3_VERSION_MINOR=%d' % sys.version_info.minor)\n"
                    "        cmake_args.append('-DPYTHON_DEFAULT_AVAILABLE=TRUE')\n"
                    "        try:\n"
                    "            import numpy as _n; cmake_args.append('-DPYTHON3_NUMPY_INCLUDE_DIRS=%s' % _n.get_include())\n"
                    "        except: pass\n"
                )
                src = src.replace("    if build_headless:", block + "    if build_headless:")
                open(f, "w").write(src)
                print("[WheelBuilder] patched setup.py for Android cmake args")
                PYEOF
                python /tmp/wb_android_patch.py
                sed -i.bak '/add_subdirectory.*android/d' "${OCV}/opencv/samples/CMakeLists.txt" 2>/dev/null || true
                """#
        }
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/opencv/opencv-python-ios-92.patch"
        ]
    }

    public func apply_patches(target: Path, working_dir: Path) async throws {
        for url in patches() {
            let patch_file = try await downloadURL(url: url, to: working_dir)
            
            try await git_apply(file: patch_file, target: target)
        }
    }
    
    public func build_wheel(working_dir: Path, version: String?, wheels_dir: Path) async throws {
        let tag = version ?? "92"
        let cloneDir = wheels_dir + "opencv-python-\(tag)"
        let proc = Process()
        proc.executablePath = .git
        let arguments: [String] = [
            "clone", "--recursive", "--branch", tag, "--depth", "1",
            "https://github.com/opencv/opencv-python.git",
            cloneDir.string
        ]
        print("git", arguments)
        proc.arguments = arguments
        try proc.run()
        proc.waitUntilExit()

        if cloneDir.exists {
            try await apply_patches(target: cloneDir, working_dir: working_dir)
            print(Self.self, "cibuildwheel", cloneDir)
            try await Process.cibuildwheel(
                target: cloneDir,
                platform: platform,
                env: env(),
                output: wheels_dir
            )
            try? cloneDir.delete()
        }
    }


    // public static func supported_platforms() throws -> [any PlatformProtocol] {
    //     [
    //         try Platforms.Android_arm64(),
    //         //try Platforms.Android_x86_64()
    //     ]
    // }
}
