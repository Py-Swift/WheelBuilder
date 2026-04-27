//
//  Cryptography.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Cryptography: MaturinWheelProtocol {
   
    
    public func env() throws -> [String : String] {
        var env = try maturin_env()
        env["OPENSSL_DIR"] = (root + "openssl/\(platform.sdk_arch)").string
        if platform.get_sdk() != .android {
            // cryptography's pyproject.toml requires cffi + setuptools in addition to maturin.
            // With --no-isolation these must all be pre-installed by CIBW_BEFORE_BUILD.
            env["CIBW_BEFORE_BUILD"] = "pip install maturin cffi setuptools"
        }
        return env
    }
    
    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [Openssl.self]
    }
    

}
