//
//  Netifaces.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

public final class Netifaces: CiWheelProtocol {
    public static let name: String = "netifaces"
    
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
    
    
}
