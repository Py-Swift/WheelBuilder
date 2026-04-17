//
//  Matplotlib.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation


@WheelClass
public final class Matplotlib: CiWheelProtocol {

    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake ninja"
        //env["CIBW_TEST_SKIP"] = "*"
        return env
    }

    public func pre_build(target: Path) async throws {
        // replace "meson-python>=0.13.1,!=0.17.*" with "meson-python>=0.13.1"
        
        let pyproject = target + "pyproject.toml"
        var contents = try String(contentsOf: pyproject.url)
        //fatalError(contents)
        contents = contents.replacingOccurrences(of: "meson-python>=0.13.1,<0.17.0", with: "meson-python>=0.13.1")
        try contents.write(to: pyproject.url, atomically: true, encoding: .utf8)

    }
    
    public func patches() -> [URL] {
        [
            //"https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/matplotlib.patch"
        ]
    }
}

