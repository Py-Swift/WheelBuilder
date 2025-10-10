//
//  CiWheels.swift
//  WheelBuilder
//
//  Created by CodeBuilder on 07/10/2025.
//
import PathKit
import Foundation

let processInfo = ProcessInfo.processInfo

public enum BuildTarget: CustomStringConvertible {
    case pypi(String)
    case local(Path)
    case url(URL)
    
    public var description: String {
        switch self {
        case .pypi(let string):
            string
        case .local(let path):
            path.string
        case .url(let url):
            url.path()
        }
    }
}


extension Dictionary where Key == String, Value == String {
    static func +(l: Self, r: Self) -> Self {
        l.merging(r) { _, new in
            new
        }
    }
}
