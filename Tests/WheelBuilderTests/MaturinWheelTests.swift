//
//  MaturinWheelTests.swift
//  WheelBuilder
//
import XCTest
@testable import WheelBuilder
import PathKit
@testable import CiWheels
@testable import PlatformInfo
@testable import Platforms
@testable import Tools


fileprivate func build_test(working_dir: Path, wheel: any MaturinWheelProtocol.Type, py_cache: CachedPython) async throws {
    let wheels_dir = working_dir + "wheels"
    try wheels_dir.mkpath()
    
    
    
    let platforms: [any PlatformProtocol] = [
        try Platforms.Iphoneos(),
        try Platforms.IphoneSimulator_arm64(),
        try Platforms.IphoneSimulator_x86_64()
    ]
    
    for platform in platforms {
        let wheel = wheel.new(version: nil, platform: platform)
        try await wheel.build_wheel(
            target: working_dir,
            py_cache: py_cache,
            output: wheels_dir,
            subfix: "_x86_64.whl"
        )
    }
    
    print("############## Wheels ##############")
    let wheels_result = wheels_dir.map(\.lastComponent)
    print(wheels_result)
    print("####################################")
    XCTAssertEqual(wheels_dir.map(\.self).count, 3, wheels_result.description)
    
}


final class MaturinWheelTests: XCTestCase {
    
    static let python3_13: CachedPython = .init()
    
    
    
    func test_environment() throws {
        for (k,v) in ProcessInfo.processInfo.environment {
            print(k,v)
        }
    }
    
    func test_0_python_download() async throws {
        try await withTemp {tmp in
            try await Self.python3_13.download(version: "3.13", build: "b10")
            
            XCTAssertTrue(Self.python3_13.python.exists)
        }
    }
    
    func test_cryptography() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Cryptography.self, py_cache: Self.python3_13)
        }
    }
    
    func test_pendulum() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Pendulum.self, py_cache: Self.python3_13)
        }
    }
    
    func test_pydantic_core() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Pydantic_core.self, py_cache: Self.python3_13)
        }
    }
    
}
