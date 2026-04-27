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
            // Three patches for Android cross-compilation:
            //
            // 1. skbuild / ctypes dlopen fix: PBS Android Python's ctypes/__init__.py does
            //    dlopen(libpython3.x.so) — an Android ELF that can't load on macOS.
            //    Create a dummy macOS dylib at the expected path so the dlopen succeeds.
            //
            // 2. PYTHON3_INCLUDE_PATH + PYTHON3_NUMPY_INCLUDE_DIRS missing for Android.
            //    Root cause: find_python() uses CACHE INTERNAL (which in cmake <3.21 had
            //    implicit FORCE, but even in >=3.21 a fresh entry IS created as ""). For
            //    Android it skips find_package(PythonLibs) so PYTHON3_INCLUDE_PATH stays "".
            //    It also skips numpy detection so PYTHON3_NUMPY_INCLUDE_DIRS stays "".
            //    scikit-build passes the correct paths via -D flags but under different names:
            //      PYTHON3_INCLUDE_DIR  (not PYTHON3_INCLUDE_PATH)
            //      Python3_NumPy_INCLUDE_DIRS (not PYTHON3_NUMPY_INCLUDE_DIRS, case differs)
            //    Fix: APPEND to OpenCVDetectPython.cmake AFTER all find_python() calls.
            //    Running after find_python ensures we overwrite its empty terminal writes.
            //    Conditions are WITHOUT an ANDROID guard so they work regardless of whether
            //    cmake's ANDROID variable is set (depends on whether NDK toolchain is used).
            //
            // 3. Android sample APKs: opencv's cmake includes sample APK targets (15-puzzle
            //    etc.) that need Gradle + Java SDK — not present on the CI runner. Remove the
            //    add_subdirectory(android) line from samples/CMakeLists.txt.
            env["CIBW_BEFORE_BUILD_ANDROID"] = """
                OCV="${GITHUB_WORKSPACE}/output/wheels/opencv-python-92/opencv"; \\
                PYVER=$(python -c "import sys; v=sys.version_info; print(f'{v.major}.{v.minor}')") && \\
                PBS_LIB=$(python -c "import sys,os; print(os.path.join(os.path.dirname(sys.prefix), 'pbs', 'python', 'lib'))") && \\
                mkdir -p "$PBS_LIB" && \\
                printf 'void _dummy(void){}' | cc -x c - -dynamiclib -o "$PBS_LIB/libpython${PYVER}.so" 2>/dev/null || true; \\
                rm -rf "${GITHUB_WORKSPACE}/output/wheels/opencv-python-92/_skbuild" 2>/dev/null || true; \\
                printf '%s\\n' \\
                  '# Cross-compile fallback: set opencv Python vars from scikit-build -D vars.' \\
                  '# Runs AFTER find_python() so it overwrites its empty terminal writes.' \\
                  '# PYTHON3_INCLUDE_PATH  <- PYTHON3_INCLUDE_DIR (scikit-build variable)' \\
                  '# PYTHON3_NUMPY_INCLUDE_DIRS <- Python3_NumPy_INCLUDE_DIRS (scikit-build,' \\
                  '#   note capitalization difference vs opencvs all-caps variable)' \\
                  'if(NOT PYTHON3_INCLUDE_PATH AND PYTHON3_INCLUDE_DIR)' \\
                  '  set(PYTHON3_INCLUDE_PATH "${PYTHON3_INCLUDE_DIR}" CACHE INTERNAL "" FORCE)' \\
                  'endif()' \\
                  'if(NOT PYTHON3_NUMPY_INCLUDE_DIRS AND Python3_NumPy_INCLUDE_DIRS)' \\
                  '  set(PYTHON3_NUMPY_INCLUDE_DIRS "${Python3_NumPy_INCLUDE_DIRS}" CACHE PATH "" FORCE)' \\
                  'endif()' \\
                  >> "$OCV/cmake/OpenCVDetectPython.cmake" 2>/dev/null || true; \\
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


    public static func supported_platforms() throws -> [any PlatformProtocol] {
        [
            try Platforms.Android_arm64(),
            //try Platforms.Android_x86_64()
        ]
    }
}
