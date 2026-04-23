//
//  Aiohttp.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Aiohttp: CiWheelProtocol {
    
    public func env() throws -> [String: String] {
        var env = base_env()
        if platform.get_sdk() == .android {
            env["CIBW_ENVIRONMENT_ANDROID"] = "LDFLAGS=\"$LDFLAGS -lc++_shared\""
        }
        return env
    }
}

