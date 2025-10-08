import XCTest
@testable import WheelBuilder
import PathKit
@testable import CiWheels
@testable import PlatformInfo
@testable import Platforms

fileprivate func build_test(working_dir: Path,wheel: any CiWheelProtocol) async throws {
    let wheels_dir = working_dir + "wheels"
    try wheels_dir.mkpath()
    
    
    
    let platforms: [any PlatformProtocol] = [
        try Platforms.Iphoneos(),
        try Platforms.IphoneSimulator_arm64(),
        try Platforms.IphoneSimulator_x86_64()
    ]
    
    for platform in platforms {
        try await wheel.build_wheel(platform: platform, working_dir: working_dir, wheels_dir: wheels_dir)
    }
    
    print("############## Wheels ##############")
    let wheels_result = wheels_dir.map(\.lastComponent)
    print(wheels_result)
    print("####################################")
    XCTAssertEqual(wheels_dir.map(\.self).count, 3, wheels_result.description)
    
}

func run_build_test(wheel: any CiWheelProtocol) async throws {
    let tmp = try Path.uniqueTemporary()
    defer {
        try! tmp.delete()
    }
    let wheels_dir = tmp + "wheels"
    try wheels_dir.mkpath()
    
    try await build_test(working_dir: tmp, wheel: wheel)
}

func withTemp(completion: @escaping (Path)async throws -> Void) async throws {
    let tmp = try Path.uniqueTemporary()
    defer {
        try! tmp.delete()
    }
    try await completion(tmp)
}

final class CfiiTester: XCTestCase {
    func test_wheel() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Cffi())
        }
    }
}





final class WheelBuilderTests {
    func test_aiohttp() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Aiohttp(version: ""))
        }
    }
    
    func test_apsw() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Apsw(version: ""))
        }
    }
    
    func test_atom() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Atom(version: ""))
        }
    }
    
    
    
    func test_bitarray() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Bitarray(version: ""))
        }
    }
    
//    func test_() async throws {
//        try await withTemp { tmp in
//            let wheels_dir = tmp + "wheels"
//            try wheels_dir.mkpath()
//            
//            try await build_test(working_dir: tmp, wheel: CiWheels.SQLAlchemy(version: ""))
//        }
//    }
    
    func test_contourpy() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Contourpy(version: ""))
        }
    }
    
    func test_coverage() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Coverage(version: ""))
        }
    }
    
    
    func test_kiwisolver() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Kiwisolver(version: ""))
        }
    }
    
//    func test_lxml() async throws {
//        try await withTemp { tmp in
//            let wheels_dir = tmp + "wheels"
//            try wheels_dir.mkpath()
//            
//            try await build_test(working_dir: tmp, wheel: CiWheels.Lxml(version: ""))
//        }
//    }
    
    func test_materialyoucolor() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Materialyoucolor(version: ""))
        }
    }
    
    func test_matplotlib() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Matplotlib(version: ""))
        }
    }
    
    func test_msgpack() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Msgpack(version: ""))
        }
    }
    
    func test_netifaces() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.SQLAlchemy(version: ""))
        }
    }
    
    func test_pandas() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Pandas(version: ""))
        }
    }
    
    func test_pycryptodome() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.SQLAlchemy(version: ""))
        }
    }
    
    func test_pymunk() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Pymunk(version: ""))
        }
    }
    
    
    func test_SQLAlchemy() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.SQLAlchemy(version: ""))
        }
    }
    
    func test_ujson() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Ujson(version: ""))
        }
    }
    
    func test_zeroconf() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Zeroconf(version: ""))
        }
    }
}
