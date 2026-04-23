//
//  pycryptodome.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Pycryptodome: CiWheelProtocol {

    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        // p4a: depends = ['cffi'] which itself depends on libffi
        guard platform.get_sdk() == .android else { return [] }
        return [Libffi.self]
    }
}
