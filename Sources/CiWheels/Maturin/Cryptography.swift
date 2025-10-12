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
   
    
    public func env(platform: any PlatformProtocol) throws -> [String : String] {
        var env = base_env()
        env["OPENSSL_DIR"] = (root + "openssl/\(platform.sdk_arch)").string //"/usr/local/Cellar/openssl@3/3.5.2"
        return env
    }
    
    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [Openssl.self]
    }
    

}
