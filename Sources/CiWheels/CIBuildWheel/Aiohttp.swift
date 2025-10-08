//
//  Aiohttp.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

public class Aiohttp: CiWheelProtocol {
    public static let name: String = "aiohttp"
    
    public var version: String?
        
    public let build_target: BuildTarget = .pypi("aiohttp")
    
    public init(version: String? = nil) {
        self.version = version
    }
    
    
}

