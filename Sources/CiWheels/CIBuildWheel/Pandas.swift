//
//  Pandas.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation
import Tools

@WheelClass
public final class Pandas: MesonWheelProtocol {
    
    public func env() throws -> [String : String] {
        var env = try meson_env()
        env["CIBW_BEFORE_BUILD_IOS"] = "env -u SDKROOT -u IPHONEOS_DEPLOYMENT_TARGET pip install numpy meson-python meson Cython"
        env["CIBW_CONFIG_SETTINGS_IOS"] = "setup-args=--cross-file=/tmp/pandas-ios-meson-cross.ini setup-args=--native-file=/tmp/pandas-ios-meson-native.ini"
        env["CIBW_ENVIRONMENT_IOS"] = [
            "PIP_EXTRA_INDEX_URL=\"https://pypi.anaconda.org/pyswift/simple\"",
            "PIP_PREFER_BINARY=\"1\"",
            "CFLAGS=\"-g0\"",
            "LDFLAGS=\"\""
        ].joined(separator: " ")
        if platform.get_sdk() == .android {
            // p4a: LDFLAGS += -landroid -lc++_shared (for symbols like _ZTVSt12length_error).
            // PKG_CONFIG_PATH="" prevents actions/setup-python's macOS Python pkgconfig from
            // shadowing the android Python pkgconfig set via PKG_CONFIG_LIBDIR by cibuildwheel.
            env["CIBW_ENVIRONMENT_ANDROID"] = "LDFLAGS=\"$LDFLAGS -landroid -lc++_shared\" PKG_CONFIG_PATH=\"\""
        }
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
        // The patch adds ini/sh files to the source tree that are only
        // needed in /tmp/ (written by pre_build). Remove them so that
        // cibuildwheel's re-archive doesn't produce absolute-path tar entries.
        for name in ["ios-meson-cross.ini", "ios-meson-native.ini",
                     "ios-native-cc.sh", "ios-native-cxx.sh"] {
            try? (target + name).delete()
        }
    }

    public func pre_build(target: Path) async throws {
        try write_meson_cross_file()
        guard platform.get_sdk() != .android else { return }

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
            c = '/tmp/pandas-ios-native-cc.sh'
            cpp = '/tmp/pandas-ios-native-cxx.sh'
            objc = '/tmp/pandas-ios-native-cc.sh'
            objcpp = '/tmp/pandas-ios-native-cxx.sh'
            ar = '/usr/bin/ar'
            strip = '/usr/bin/strip'
            """

        let nativeCc = """
            #!/bin/bash
            unset SDKROOT
            unset IPHONEOS_DEPLOYMENT_TARGET
            exec /usr/bin/cc "$@"
            """

        let nativeCxx = """
            #!/bin/bash
            unset SDKROOT
            unset IPHONEOS_DEPLOYMENT_TARGET
            exec /usr/bin/c++ "$@"
            """

        try Path("/tmp/pandas-ios-meson-cross.ini").write(crossIni)
        try Path("/tmp/pandas-ios-meson-native.ini").write(nativeIni)
        try Path("/tmp/pandas-ios-native-cc.sh").write(nativeCc)
        try Path("/tmp/pandas-ios-native-cxx.sh").write(nativeCxx)

        let chmod = Process()
        chmod.executableURL = URL(filePath: "/bin/chmod")
        chmod.arguments = ["+x",
            "/tmp/pandas-ios-native-cc.sh",
            "/tmp/pandas-ios-native-cxx.sh"
        ]
        try chmod.run()
        chmod.waitUntilExit()
    }
}