//
//  Pymunk.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

//@WheelClass
//public final class Pymunk: CiWheelProtocol {
//    
//}

@WheelClass
public final class Pymunk: CiWheelProtocol {

    public func env() throws -> [String: String] {
        var env = base_env()
        if platform.get_sdk() == .android {
            // p4a: LDFLAGS += -llog (Chipmunk cpMessage) -lm (older Android)
            env["CIBW_ENVIRONMENT_ANDROID"] = "LDFLAGS=\"$LDFLAGS -llog -lm\""
        }
        return env
    }

    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [Libffi.self]
    }
}

