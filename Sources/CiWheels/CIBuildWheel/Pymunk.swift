//
//  Pymunk.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation
import Platforms

//@WheelClass
//public final class Pymunk: CiWheelProtocol {
//    
//}

@WheelClass
public final class Pymunk: CiWheelProtocol {

    public func env() throws -> [String: String] {
        var env = base_env()
        // pymunk's pyproject.toml includes PyPy selectors (pp310-*, pp311-*) which
        // require explicit `enable: [pypy]` in cibuildwheel 3.4.1 — restrict to CPython.
        env["CIBW_BUILD"] = "cp313-* cp314-*"
        if platform.get_sdk() == .android {
            // p4a: LDFLAGS += -llog (Chipmunk cpMessage) -lm (older Android)
            // cffi for Android is available on pyswift (same as iOS)
            env["CIBW_ENVIRONMENT_ANDROID"] = [
                "LDFLAGS=\"$LDFLAGS -llog -lm\"",
                "PIP_EXTRA_INDEX_URL=\"https://pypi.anaconda.org/pyswift/simple\""
            ].joined(separator: " ")
        }
        return env
    }

    public static func supported_platforms() throws -> [any PlatformProtocol] {
        [
            try Platforms.Android_arm64(),
            try Platforms.Android_x86_64()
        ]
    }
}

