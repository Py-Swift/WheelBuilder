//
//  Apsw.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation


public class Apsw: CiWheelProtocol {
    public static let name: String = "apsw"
    
    public var version: String?
    
    //public var output: Path
    
    public let build_target: BuildTarget = .pypi(name)
    
    public init(version: String? = nil) {
        self.version = version
    }
    
    public func env(platform: any PlatformProtocol) throws -> [String : String] {
        var env = base_env(platform: platform)
        env["CIBW_TEST_SKIP"] = "*"
        return env
    }
}
