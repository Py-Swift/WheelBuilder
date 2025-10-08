//
//  Bitarray.swift
//  WheelBuilder


import PlatformInfo
import PathKit

public class Bitarray: CiWheelProtocol {
    public static let name: String = "bitarray"
    
    public var version: String?
    
    //public var output: Path
    
    public let build_target: BuildTarget = .pypi(Bitarray.name)
    
    public init(version: String? = nil) {
        self.version = version
    }
    
}
