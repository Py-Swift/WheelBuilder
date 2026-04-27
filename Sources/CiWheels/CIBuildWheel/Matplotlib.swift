//
//  Matplotlib.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation


@WheelClass
public final class Matplotlib: MesonWheelProtocol {

    public func env() throws -> [String : String] {
        var env = try meson_env()
        if platform.get_sdk() == .android {
            // p4a: need_stl_shared=True, CXXFLAGS += -Wno-c++11-narrowing
            env["CIBW_ENVIRONMENT_ANDROID"] = "CXXFLAGS=\"$CXXFLAGS -Wno-c++11-narrowing\" PKG_CONFIG_PATH=\"\""
        }
        return env
    }

    public func pre_build(target: Path) async throws {
        // Fix meson-python version constraint (drop !=0.17.* exclusion)
        let pyproject = target + "pyproject.toml"
        var contents = try String(contentsOf: pyproject.url)
        contents = contents.replacingOccurrences(of: "meson-python>=0.13.1,<0.17.0", with: "meson-python>=0.13.1")
        try contents.write(to: pyproject.url, atomically: true, encoding: .utf8)

        try write_meson_cross_file()
    }

    public func patches() -> [URL] {
        [
            //"https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/matplotlib.patch"
        ]
    }
}
