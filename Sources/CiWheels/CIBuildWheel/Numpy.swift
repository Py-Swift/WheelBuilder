//
//  Untitled.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation

@WheelClass
public final class Numpy: CiWheelProtocol {
    
    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_BEFORE_BUILD"] = ""
        env["CIBW_TEST_SKIP"] = "*"
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/numpy.patch"
        ]
    }
}
