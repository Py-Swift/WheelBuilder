//
//  SDK.swift
//  WheelBuilder
//
//  Created by CodeBuilder on 07/10/2025.
//

public enum SDK: String, CustomStringConvertible, @unchecked Sendable {
    case iphoneos
    case iphonesimulator
    case macos
    
    public var description: String { rawValue }
    
    
    
}
