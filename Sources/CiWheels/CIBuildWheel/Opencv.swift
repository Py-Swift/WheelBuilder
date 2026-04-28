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
                // cmake preload file (written by BEFORE_BUILD) short-circuits
                // find_python() by pre-setting PYTHON3INTERP_FOUND=TRUE.
                // find_python() checks `if(NOT ${found})` at its very top — if
                // already TRUE it skips the entire body, meaning the CACHE INTERNAL
                // FORCE exports (which would clear PYTHON3_INCLUDE_PATH) never run.
                // We also pre-set all variables find_python() would have exported.
                "CMAKE_ARGS=\"-C /tmp/cibw_ocv_preload.cmake\""
            ].joined(separator: " ")
            // Patches for Android cross-compilation:
            //
            // 1. ctypes dlopen fix: PBS Android Python's ctypes/__init__.py does
            //    dlopen(libpython3.x.so) — an Android ELF that can't load on macOS.
            //    Create a dummy macOS dylib at the expected path so dlopen succeeds.
            //
            // 2. PYTHON3_INCLUDE_PATH / PYTHON3_NUMPY_INCLUDE_DIRS:
            //    find_python() skips all detection for Android (guarded by
            //    `if(NOT ANDROID AND NOT APPLE_FRAMEWORK)`). At the end of its body
            //    it exports PYTHON3_INCLUDE_PATH as CACHE INTERNAL "" — which implies
            //    FORCE, overwriting any -D or preload value to "".
            //    The iOS patch in setup.py avoids this by passing
            //    -DPYTHON3INTERP_FOUND=ON, which makes find_python() skip its body
            //    entirely (checked at the top: `if(NOT ${found})`). We use the same
            //    mechanism via the cmake preload file: set PYTHON3INTERP_FOUND TRUE
            //    with FORCE so find_python() short-circuits and never clears anything.
            //    All variables find_python() would have set are pre-populated in the
            //    preload using paths computed from the active PBS Python.
            //
            // 3. Android sample APKs need Gradle + Java — not on the CI runner.
            //    Remove add_subdirectory(android) from opencv/samples/CMakeLists.txt.
            env["CIBW_BEFORE_BUILD_ANDROID"] = """
                OCV="${GITHUB_WORKSPACE}/output/wheels/opencv-python-92/opencv"; \\
                PYVER=$(python -c "import sys; v=sys.version_info; print(f'{v.major}.{v.minor}')") && \\
                PBS_LIB=$(python -c "import sys,os; print(os.path.join(os.path.dirname(sys.prefix), 'pbs', 'python', 'lib'))") && \\
                mkdir -p "$PBS_LIB" && \\
                printf 'void _dummy(void){}' | cc -x c - -dynamiclib -o "$PBS_LIB/libpython${PYVER}.so" 2>/dev/null || true; \\
                rm -rf "${GITHUB_WORKSPACE}/output/wheels/opencv-python-92/_skbuild" 2>/dev/null || true; \\
                PYINC=$(python -c "import sysconfig; print(sysconfig.get_path('include'))"); \\
                PYVERMAJ=$(python -c "import sys; print(sys.version_info.major)"); \\
                PYVERMIN=$(python -c "import sys; print(sys.version_info.minor)"); \\
                NUMPYINC=$(python -c "import numpy; print(numpy.get_include())"); \\
                echo "[WheelBuilder] PYINC=$PYINC NUMPYINC=$NUMPYINC ver=$PYVERMAJ.$PYVERMIN"; \\
                printf 'set(PYTHON3INTERP_FOUND TRUE CACHE BOOL "" FORCE)\\nset(PYTHON3_VERSION_STRING "%s.%s" CACHE INTERNAL "" FORCE)\\nset(PYTHON3_VERSION_MAJOR "%s" CACHE INTERNAL "" FORCE)\\nset(PYTHON3_VERSION_MINOR "%s" CACHE INTERNAL "" FORCE)\\nset(PYTHON3_INCLUDE_PATH "%s" CACHE INTERNAL "" FORCE)\\nset(PYTHON3_NUMPY_INCLUDE_DIRS "%s" CACHE PATH "" FORCE)\\n' "$PYVERMAJ" "$PYVERMIN" "$PYVERMAJ" "$PYVERMIN" "$PYINC" "$NUMPYINC" > /tmp/cibw_ocv_preload.cmake; \\
                echo "[WheelBuilder] preload:"; cat /tmp/cibw_ocv_preload.cmake; \\
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
