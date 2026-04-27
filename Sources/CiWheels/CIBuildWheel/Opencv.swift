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
            // Two issues to fix for Android cross-compilation:
            //
            // 1. opencv's cmake runs `execute_process(python -c "import numpy; print(...)")` to
            //    detect the numpy include path. This fails because the PBS Android Python's
            //    ctypes/__init__.py tries to dlopen(libpython3.x.so) — an Android ELF — which
            //    cannot be loaded on macOS host. We bypass this by prepending cmake code to
            //    OpenCVDetectPython.cmake that pre-sets PYTHON3_NUMPY_INCLUDE_DIRS from
            //    scikit-build's Python3_NumPy_INCLUDE_DIRS (already passed via -D flag),
            //    so opencv skips the execute_process check entirely.
            //
            // 2. opencv's cmake builds/installs Android sample APKs (e.g. 15-puzzle) which
            //    require Gradle + Java SDK — not present on the macOS CI runner. We remove the
            //    add_subdirectory(android) call from samples/CMakeLists.txt so those targets
            //    are never created.
            env["CIBW_BEFORE_BUILD_ANDROID"] = """
                PYVER=$(python -c "import sys; v=sys.version_info; print(f'{v.major}.{v.minor}')") && \\
                PBS_LIB=$(python -c "import sys,os; print(os.path.join(os.path.dirname(sys.prefix), 'pbs', 'python', 'lib'))") && \\
                mkdir -p "$PBS_LIB" && \\
                printf 'void _dummy(void){}' | cc -x c - -dynamiclib -o "$PBS_LIB/libpython${PYVER}.so" 2>/dev/null || true; \\
                printf 'if(NOT DEFINED PYTHON3_NUMPY_INCLUDE_DIRS OR PYTHON3_NUMPY_INCLUDE_DIRS STREQUAL "")\\n  if(DEFINED Python3_NumPy_INCLUDE_DIRS AND NOT Python3_NumPy_INCLUDE_DIRS STREQUAL "")\\n    set(PYTHON3_NUMPY_INCLUDE_DIRS "${Python3_NumPy_INCLUDE_DIRS}" CACHE PATH "" FORCE)\\n  endif()\\nendif()\\n' > /tmp/np_patch.cmake && \\
                cat /tmp/np_patch.cmake "${GITHUB_WORKSPACE}/output/wheels/opencv-python-92/opencv/cmake/OpenCVDetectPython.cmake" > /tmp/OCV_tmp.cmake && \\
                cp /tmp/OCV_tmp.cmake "${GITHUB_WORKSPACE}/output/wheels/opencv-python-92/opencv/cmake/OpenCVDetectPython.cmake" 2>/dev/null || true; \\
                sed -i.bak '/add_subdirectory.*android/d' "${GITHUB_WORKSPACE}/output/wheels/opencv-python-92/opencv/samples/CMakeLists.txt" 2>/dev/null || true
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
