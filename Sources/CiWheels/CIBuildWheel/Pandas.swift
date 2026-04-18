//
//  Pandas.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation
import Tools

@WheelClass
public final class Pandas: CiWheelProtocol {
    
    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake ninja"

        env["CIBW_TEST_COMMAND_IOS"] = ""
        //env["CIBW_BUILD_FRONTEND"] = "pip; args: --no-build-isolation"
        //env["CIBW_BUILD_FRONTEND"] = "pip; args: --no-build-isolation"
        //env["CIBW_BEFORE_BUILD_IOS"] = ""
        env["CIBW_BEFORE_BUILD_IOS"] = "env -u SDKROOT -u IPHONEOS_DEPLOYMENT_TARGET pip install numpy meson-python meson Cython"
//        env["CIBW_BEFORE_BUILD_IOS"] = [
//            "env -u SDKROOT -u IPHONEOS_DEPLOYMENT_TARGET pip install numpy meson-python meson ninja Cython",
//            "mkdir -p ~/.local/share/meson/cross ~/.local/share/meson/native",
//            "cp {package}/ios-meson-cross.ini ~/.local/share/meson/cross/",
//            "cp {package}/ios-meson-native.ini ~/.local/share/meson/native/",
//            "cp {package}/ios-native-cc.sh {package}/ios-native-cxx.sh /tmp/",
//            "chmod +x /tmp/ios-native-cc.sh /tmp/ios-native-cxx.sh",
//            // "PACKAGE_DIR={package} bash {package}/scripts/cibw_before_build.sh" // only concatenates license files
//        ].joined(separator: " && ")
        env["CIBW_CONFIG_SETTINGS_IOS"] = "setup-args=--cross-file=ios-meson-cross.ini setup-args=--native-file=ios-meson-native.ini"
        env["CIBW_ENVIRONMENT_IOS"] = [
            "PIP_EXTRA_INDEX_URL=\"https://pypi.anaconda.org/pyswift/simple\"",
            "PIP_PREFER_BINARY=\"1\"",
            "CFLAGS=\"-g0\"",
            "LDFLAGS=\"\""
        ].joined(separator: " ")
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/pandas/pandas-ios.patch"
        ]
    }

    public func apply_patches(target: Path, working_dir: Path) async throws {
        for url in patches() {
            let patch_file = try await downloadURL(url: url, to: working_dir)
            
            try await git_apply(file: patch_file, target: target)
        }
    }

    public func pre_build(target: Path) async throws {
        let crossIni = """
            ; Supplementary meson cross-file for iOS builds.
            ; Tells meson that cross-compiled binaries cannot run on the build host,
            ; preventing it from trying to execute sanity-check programs that would
            ; hang on macOS (since iOS arm64 Mach-O binaries can't run on the host).

            [properties]
            needs_exe_wrapper = true

            [binaries]
            exe_wrapper = ['/usr/bin/true']
            """

        let nativeIni = """
            ; Native (build-machine) meson file for iOS cross-builds.
            ; Uses wrapper scripts that unset SDKROOT and IPHONEOS_DEPLOYMENT_TARGET
            ; so the build-machine compiler targets macOS, not iOS.

            [binaries]
            c = '/tmp/ios-native-cc.sh'
            cpp = '/tmp/ios-native-cxx.sh'
            objc = '/tmp/ios-native-cc.sh'
            objcpp = '/tmp/ios-native-cxx.sh'
            ar = '/usr/bin/ar'
            strip = '/usr/bin/strip'
            """

        let nativeCc = """
            #!/bin/bash
            # Wrapper for native (build-machine) C compiler during iOS cross-compilation.
            # Unsets iOS-related env vars that contaminate the cross-venv, forcing
            # the compiler to target macOS instead of iOS.
            unset SDKROOT
            unset IPHONEOS_DEPLOYMENT_TARGET
            exec /usr/bin/cc "$@"
            """

        let nativeCxx = """
            #!/bin/bash
            # Wrapper for native (build-machine) C++ compiler during iOS cross-compilation.
            # Unsets iOS-related env vars that contaminate the cross-venv, forcing
            # the compiler to target macOS instead of iOS.
            unset SDKROOT
            unset IPHONEOS_DEPLOYMENT_TARGET
            exec /usr/bin/c++ "$@"
            """

        try (target + "ios-meson-cross.ini").write(crossIni)
        try (target + "ios-meson-native.ini").write(nativeIni)
        try (target + "ios-native-cc.sh").write(nativeCc)
        try (target + "ios-native-cxx.sh").write(nativeCxx)

        let chmod = Process()
        chmod.executableURL = URL(filePath: "/bin/chmod")
        chmod.arguments = ["+x",
            (target + "ios-native-cc.sh").string,
            (target + "ios-native-cxx.sh").string
        ]
        try chmod.run()
        chmod.waitUntilExit()
    }
}