//
//  Matplotlib.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation

public final class Matplotlib: CiWheelProtocol {
    public static let name: String = "matplotlib"
    
    public var version: String?
    
    public var build_target: BuildTarget = .local("matplotlib")
    
    public var platform: any PlatformProtocol
    
    init(version: String? = nil, platform: any PlatformProtocol) {
        self.version = version
        self.platform = platform
    }
    
    public static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self {
        .init(version: version, platform: platform)
    }
    
    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/matplotlib.patch"
        ]
    }
}

