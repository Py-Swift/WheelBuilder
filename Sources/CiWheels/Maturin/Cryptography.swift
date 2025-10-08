//
//  Cryptography.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation


public class Cryptography: MaturinWheelProtocol {
    public static let name: String = "cryptography"
    
    public var version: String?
    
    //public var output: Path
    
    public let build_target: BuildTarget = .pypi(name)
    
    public init(version: String = "") {
        self.version = version
    }

}
