//
//  Matplotlib.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation


@WheelClass
public final class Matplotlib: CiWheelProtocol {

    
    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/matplotlib.patch"
        ]
    }
}

