//
//  Cryptography.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation


public final class Cryptography: MaturinWheelProtocol {
    public static let name: String = "cryptography"
    
    public var version: String?
    
    public var root: Path
    
    public let build_target: BuildTarget = .pypi(name)
    
    public var platform: any PlatformProtocol
    
    init(version: String? = nil, platform: any PlatformProtocol, root: Path) {
        self.version = version
        self.platform = platform
        self.root = root
    }
    
    public func env(platform: any PlatformProtocol) throws -> [String : String] {
        var env = base_env(platform: platform)
        env["OPENSSL_DIR"] = (root + "openssl/\(platform.sdk_arch)").string //"/usr/local/Cellar/openssl@3/3.5.2"
        return env
    }
    
    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [Openssl.self]
    }
    
    public static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self {
        .init(version: version, platform: platform, root: root)
    }

}
