//
//  Aiohttp.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

public final class Aiohttp: CiWheelProtocol {
    public static let name: String = "aiohttp"
    
    public var version: String?
        
    public let build_target: BuildTarget = .pypi("aiohttp")
    
    public var platform: any PlatformProtocol
    
    init(version: String? = nil, platform: any PlatformProtocol) {
        self.version = version
        self.platform = platform
    }
    
    public static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self {
        .init(version: version, platform: platform)
    }
    
    
}

