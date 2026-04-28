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
                "PKG_CONFIG_PATH=\"\"",
                // cmake preload file (written by BEFORE_BUILD) supplies
                // PYTHON3_NUMPY_INCLUDE_DIRS via CACHE PATH (without FORCE);
                // find_python()'s set(PYTHON3_NUMPY_INCLUDE_DIRS ... CACHE PATH)
                // without FORCE preserves the preload value for Android.
                // PYTHON3_INCLUDE_PATH is handled differently — see BEFORE_BUILD.
                "CMAKE_ARGS=\"-C /tmp/cibw_ocv_preload.cmake\""
            ].joined(separator: " ")
            // Patches for Android cross-compilation:
            //
            // 1. ctypes dlopen fix: PBS Android Python's ctypes/__init__.py does
            //    dlopen(libpython3.x.so) — an Android ELF that can't load on macOS.
            //    Create a dummy macOS dylib at the expected path so dlopen succeeds.
            //
            // 2. PYTHON3_NUMPY_INCLUDE_DIRS:
            //    find_python() skips numpy detection for Android. We supply it via
            //    a cmake preload (-C), which sets CACHE PATH without FORCE — cmake
            //    preserves that value when find_python() exports the same var as
            //    CACHE PATH without FORCE.
            //
            // 3. PYTHON3_INCLUDE_PATH:
            //    find_python() skips include-path detection for Android AND exports
            //    the variable as CACHE INTERNAL "". cmake CACHE INTERNAL implies
            //    FORCE, so ANY preload value would be overwritten to "".
            //    Fix: prepend cmake code to modules/python/python3/CMakeLists.txt
            //    that sets PYTHON3_INCLUDE_PATH from PYTHON3_INCLUDE_DIR (a CACHE
            //    PATH set via scikit-build's -D flag, which is preserved). This
            //    runs AFTER find_python() so CACHE INTERNAL can't clear it, and
            //    a local cmake set() takes priority over the cache in if() checks.
            //
            // 4. Android sample APKs need Gradle + Java — not on the CI runner.
            //    Remove add_subdirectory(android) from opencv/samples/CMakeLists.txt.
            env["CIBW_BEFORE_BUILD_ANDROID"] = """
                OCV="${GITHUB_WORKSPACE}/output/wheels/opencv-python-92/opencv"; \\
                PYVER=$(python -c "import sys; v=sys.version_info; print(f'{v.major}.{v.minor}')") && \\
                PBS_LIB=$(python -c "import sys,os; print(os.path.join(os.path.dirname(sys.prefix), 'pbs', 'python', 'lib'))") && \\
                mkdir -p "$PBS_LIB" && \\
                printf 'void _dummy(void){}' | cc -x c - -dynamiclib -o "$PBS_LIB/libpython${PYVER}.so" 2>/dev/null || true; \\
                rm -rf "${GITHUB_WORKSPACE}/output/wheels/opencv-python-92/_skbuild" 2>/dev/null || true; \\
                NUMPYINC=$(python -c "import numpy; print(numpy.get_include())"); \\
                echo "[WheelBuilder] NUMPYINC=$NUMPYINC"; \\
                printf 'set(PYTHON3_NUMPY_INCLUDE_DIRS "%s" CACHE PATH "" FORCE)\\n' "$NUMPYINC" > /tmp/cibw_ocv_preload.cmake; \\
                PY3_CMAKE="$OCV/modules/python/python3/CMakeLists.txt"; \\
                if [ -f "$PY3_CMAKE" ] && ! grep -q WheelBuilder "$PY3_CMAKE"; then \\
                  printf '# WheelBuilder: set PYTHON3_INCLUDE_PATH from PYTHON3_INCLUDE_DIR for Android\\n# (CACHE INTERNAL implies FORCE so preload cannot set this; local set wins)\\nif(NOT PYTHON3_INCLUDE_PATH AND PYTHON3_INCLUDE_DIR)\\n  set(PYTHON3_INCLUDE_PATH "${PYTHON3_INCLUDE_DIR}")\\nendif()\\n' | cat - "$PY3_CMAKE" > /tmp/_wb_py3.cmake && mv /tmp/_wb_py3.cmake "$PY3_CMAKE" && echo "[WheelBuilder] patched $PY3_CMAKE" || echo "[WheelBuilder] patch FAILED"; \\
                fi; \\
                sed -i.bak '/add_subdirectory.*android/d' "$OCV/samples/CMakeLists.txt" 2>/dev/null || true
                """
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
