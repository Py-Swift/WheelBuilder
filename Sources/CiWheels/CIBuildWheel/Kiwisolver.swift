//
//  Kiwisolver.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Kiwisolver: CiWheelProtocol {

    public func env() throws -> [String: String] {
        var env = base_env()
        if platform.get_sdk() == .android {
            // p4a: need_stl_shared=True, LDFLAGS += -shared
            env["CIBW_ENVIRONMENT_ANDROID"] = "LDFLAGS=\"$LDFLAGS -lc++_shared -shared\""
        }
        return env
    }
}


