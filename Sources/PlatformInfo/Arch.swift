//
//  Arch.swift
//  WheelBuilder
//


public enum Arch: String, CustomStringConvertible {
    case arm64
    case x86_64
    
    public var description: String { rawValue }
    
}

