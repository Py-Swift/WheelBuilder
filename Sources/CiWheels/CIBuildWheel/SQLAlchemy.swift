//
//  SQLAlchemy.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class SQLAlchemy: CiWheelProtocol {
 
    public func env(platform: any PlatformProtocol) throws -> [String : String] {
        var env = base_env()
        env["CIBW_TEST_SKIP"] = "*"
        return env
    }
    
}
