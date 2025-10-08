//
//  Coverage.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

public class Coverage: CiWheelProtocol {
    public static let name: String = "coverage"
    
    public var version: String?
    
    //public var output: Path
    
    public let build_target: BuildTarget = .pypi(name)
    
    public init(version: String? = nil) {
        self.version = version
    }
    
    
}

