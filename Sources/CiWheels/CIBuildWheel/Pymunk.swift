//
//  Pymunk.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation


public class Pymunk: CiWheelProtocol {
    public static let name: String = "pymunk"
    
    public var version: String?
    
    //public var output: Path
    
    public let build_target: BuildTarget = .pypi(name)
    
    public init(version: String? = nil) {
        self.version = version
    }
    
    
}

