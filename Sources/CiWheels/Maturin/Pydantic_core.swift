//
//  Pydantic_core.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation


public class Pydantic_core: MaturinWheelProtocol {
    public static let name: String = "pydantic_core"
    
    public var version: String?
    
    //public var output: Path
    
    public let build_target: BuildTarget = .pypi(name)
    
    public init(version: String = "") {
        self.version = version
    }

}


