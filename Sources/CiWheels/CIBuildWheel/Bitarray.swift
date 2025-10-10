//
//  Bitarray.swift
//  WheelBuilder


import PlatformInfo
import PathKit

public final class Bitarray: CiWheelProtocol {
    public static let name: String = "bitarray"
    
    public var version: String?
    
    //public var output: Path
    
    public let build_target: BuildTarget = .pypi(Bitarray.name)
    
    public var platform: any PlatformProtocol
    
    init(version: String? = nil, platform: any PlatformProtocol) {
        self.version = version
        self.platform = platform
    }
    
    public static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self {
        .init(version: version, platform: platform)
    }
    
}
