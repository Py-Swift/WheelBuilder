//
//  Matplotlib.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit

public class Matplotlib: CiWheelProtocol {
    public static let name: String = "matplotlib"
    
    public var version: String?
    
    //public var output: Path
    
    public var build_target: BuildTarget = .local("matplotlib")
    
    public init(version: String? = nil) {
        self.version = version
    }
    
}

