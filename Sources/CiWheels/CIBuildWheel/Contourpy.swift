//
//  Contourpy.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation


public final class Contourpy: CiWheelProtocol {
    public static let name: String = "contourpy"
    
    public var version: String?
    
    //public var output: Path
    
    public let build_target: BuildTarget = .pypi(name)
    
    public var platform: any PlatformProtocol
    
    init(version: String? = nil, platform: any PlatformProtocol) {
        self.version = version
        self.platform = platform
    }
    
    public static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self {
        .init(version: version, platform: platform)
    }
    
    public func env(platform: any PlatformProtocol) throws -> [String : String] {
        var env = base_env(platform: platform)
        env["CIBW_TEST_SKIP"] = "*"
        return env
    }
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/contourpy.patch"
        ]
    }
}
