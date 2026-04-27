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
        return env
    }
    
    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [Openssl.self]
    }
    

}
