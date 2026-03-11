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
        env["CIBW_BEFORE_BUILD_IOS"] = [
            "mkdir -p ~/.local/share/meson/cross ~/.local/share/meson/native",
            "cp {package}/ios-meson-cross.ini ~/.local/share/meson/cross/",
            "cp {package}/ios-meson-native.ini ~/.local/share/meson/native/",
            "cp {package}/ios-native-cc.sh {package}/ios-native-cxx.sh /tmp/",
            "chmod +x /tmp/ios-native-cc.sh /tmp/ios-native-cxx.sh",
            "PACKAGE_DIR={package} bash {package}/scripts/cibw_before_build.sh"
        ].joined(separator: " && ")
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
}