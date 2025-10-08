//
//  Env.swift
//  WheelBuilder
//
//  Created by CodeBuilder on 07/10/2025.
//
import PathKit


public enum Env {
    
    public class CFlags: CustomStringConvertible {
        
        public var elements: [Value]
        
        public init(elements: [Value]) {
            self.elements = elements
        }
        
        public init(sdk_root: Path) {
            elements = [
                .include(sdk_root + "usr/include")
            ]
        }
        
        public func append(value: Value) {
            elements.append(value)
        }
        
        public func append(contentsOf: [Value]) {
            elements.append(contentsOf: contentsOf)
        }
        
        
        public var description: String {
            elements.map(\.description).joined(separator: " ")
        }
    }
    
    public class LDFlags: CustomStringConvertible {
        
        public var elements: [Value]
        
        public init(elements: [Value]) {
            self.elements = elements
        }
        
        public init(arch: Arch) {
            elements = [
                .arch(arch)
            ]
        }
        
        public func append(value: Value) {
            elements.append(value)
        }
        
        public func append(contentsOf: [Value]) {
            elements.append(contentsOf: contentsOf)
        }
        
        public var description: String {
            elements.map(\.description).joined(separator: " ")
        }
    }
}


public extension Env.CFlags {
    enum Value: CustomStringConvertible {
        
        case include(Path)
        
        
        public var description: String {
            switch self {
            case .include(let path):
                "-I\(path)"
            }
        }
        
    }
}

public extension Env.LDFlags {
    enum Value: CustomStringConvertible {
        case arch(Arch)
        case framework(String)
        case library(Path)
        case framework_path(Path)
        
        public var description: String {
            switch self {
            case .arch(let arch):
                "-arch \(arch)"
            case .framework(let string):
                "-framework \(string)"
            case .library(let path):
                "-L\(path)"
            case .framework_path(let path):
                "-F\(path)"
            }
        }
    }
}
