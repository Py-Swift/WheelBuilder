//
//  Contourpy.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Contourpy: CiWheelProtocol {

    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_TEST_SKIP"] = "*"
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/contourpy.patch"
        ]
    }
}
