
//
//  MaterialYouColor.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Materialyoucolor: CiWheelProtocol {

    public func env() throws -> [String: String] {
        var env = base_env()
        if platform.get_sdk() == .android {
            // p4a: LDCXXSHARED = CXX + ' -shared', stl_lib_name = c++_shared
            env["CIBW_ENVIRONMENT_ANDROID"] = "LDFLAGS=\"$LDFLAGS -lc++_shared\""
        }
        return env
    }
}
