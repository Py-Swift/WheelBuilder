//
//  Bcrypt.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation

@WheelClass
public final class Bcrypt: CiWheelProtocol {
    
    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake ninja cython pkg-config"
        return env
    }

    
    public func patches() -> [URL] {
        ["https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/bcrypt.patch"]
    }
}
