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
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake rustc cargo"
        return env
    }

    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        // p4a: depends = ['openssl', 'cffi']
        guard platform.get_sdk() == .android else { return [] }
        return [Openssl.self, Libffi.self]
    }

    public func patches() -> [URL] {
        [
            //"https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/bcrypt.patch"
        ]
    }
}
