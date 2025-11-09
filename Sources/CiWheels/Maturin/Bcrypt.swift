//
//  Bcrypt.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation

@WheelClass
public final class Bcrypt: CiWheelProtocol {

    
    public func patches() -> [URL] {
        ["https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/bcrypt.patch"]
    }
}
