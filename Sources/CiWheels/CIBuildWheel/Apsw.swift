//
//  Apsw.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Apsw: CiWheelProtocol {


    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_TEST_SKIP"] = "*"
        return env
    }
}
