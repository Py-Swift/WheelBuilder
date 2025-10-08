//
//  Cffi.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation


public class Cffi: CiWheelProtocol {
    public static let name: String = "cffi"
    
    public var version: String?
    
    //public var output: Path
    
    public let build_target: BuildTarget = .pypi(name)
    
    public init(version: String? = nil) {
        self.version = version
    }
    
    public func pre_build(platform: any PlatformProtocol, target: Path) async throws {
        
    }
    
    public func get_cflags(platform: any PlatformProtocol) -> Env.CFlags {
        let flags = platform.cflags
        flags.append(value: .include(.init("/Volumes/CodeSSD/libs/libffi/\(platform.get_sdk())/include/ffi")))
        
        return flags
    }
    
    public func get_ldflags(platform: any PlatformProtocol) -> Env.LDFlags {
        let flags = platform.ldflags
        flags.append(value: .library(.init("/Volumes/CodeSSD/libs/libffi/\(platform.get_sdk())")))
        
        return flags
    }
    
   
}
