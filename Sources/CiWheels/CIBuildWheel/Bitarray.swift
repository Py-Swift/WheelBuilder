//
//  Bitarray.swift
//  WheelBuilder


import PlatformInfo
import PathKit

@WheelClass
public final class Bitarray: CiWheelProtocol {

    public func env() throws -> [String: String] {
        var env = base_env()
        if platform.get_sdk() == .android {
            env["CIBW_ENVIRONMENT_ANDROID"] = "LDFLAGS=\"$LDFLAGS -lc++_shared\""
        }
        return env
    }
}
