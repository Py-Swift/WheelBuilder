//
//  Opencv.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation
import Tools

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
            // 2a. PYTHON3_NUMPY_INCLUDE_DIRS missing for Android: opencv skips the numpy
            //     detection (inside "if(NOT ANDROID...)") so PYTHON3_NUMPY_INCLUDE_DIRS
            //     stays empty. Prepend FORCE-set to OpenCVDetectPython.cmake from scikit-
            //     build's Python3_NumPy_INCLUDE_DIRS (passed via -D flag). FORCE is required
            //     because find_python's non-FORCE cache writes run afterward.
            //
            // 2b. PYTHON3_INCLUDE_PATH missing for Android: find_package(PythonLibs) is
            //     skipped for Android, so PYTHON3_INCLUDE_PATH stays empty in the CACHE.
            //     modules/python/python3/CMakeLists.txt gates the module on this variable.
            //     Prepend a NORMAL variable set (no CACHE keyword) to python3/CMakeLists.txt
            //     using PYTHON3_INCLUDE_DIR (passed via -D). NORMAL variables take priority
            //     over CACHE in cmake scope lookups, bypassing the stale cache entry.
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
                printf '%s\\n' \\
                  'if(Python3_NumPy_INCLUDE_DIRS AND NOT PYTHON3_NUMPY_INCLUDE_DIRS)' \\
                  '  set(PYTHON3_NUMPY_INCLUDE_DIRS "${Python3_NumPy_INCLUDE_DIRS}" CACHE PATH "" FORCE)' \\
                  'endif()' > /tmp/ocv_np.cmake && \\
                cat /tmp/ocv_np.cmake "$OCV/cmake/OpenCVDetectPython.cmake" > /tmp/ocv_np_tmp.cmake && \\
                cp /tmp/ocv_np_tmp.cmake "$OCV/cmake/OpenCVDetectPython.cmake" 2>/dev/null || true; \\
                printf '%s\\n' \\
                  'if(NOT PYTHON3_INCLUDE_PATH AND PYTHON3_INCLUDE_DIR)' \\
                  '  set(PYTHON3_INCLUDE_PATH "${PYTHON3_INCLUDE_DIR}")' \\
                  'endif()' > /tmp/ocv_inc.cmake && \\
                cat /tmp/ocv_inc.cmake "$OCV/modules/python/python3/CMakeLists.txt" > /tmp/ocv_inc_tmp.cmake && \\
                cp /tmp/ocv_inc_tmp.cmake "$OCV/modules/python/python3/CMakeLists.txt" 2>/dev/null || true; \\
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
}
