import XCTest
@testable import WheelBuilder
import PathKit
@testable import CiWheels
@testable import PlatformInfo
@testable import Platforms

let processInfo = ProcessInfo.processInfo

fileprivate func build_test(working_dir: Path, wheel: any CiWheelProtocol.Type) async throws {
    
    
    
    let wheels_dir = working_dir + "wheels"
    try wheels_dir.mkpath()
    
    
    
    let platforms: [any PlatformProtocol] = [
        try Platforms.Iphoneos(),
        try Platforms.IphoneSimulator_arm64(),
        try Platforms.IphoneSimulator_x86_64()
    ]
    
    for platform in platforms {
        let wheel = wheel.new(version: nil, platform: platform)
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
    
    //try await build_test(working_dir: tmp, wheel: wheel)
}

func withTemp(completion: @escaping (Path)async throws -> Void) async throws {
    let tmp = try Path.uniqueTemporary()
    defer {
        try! tmp.delete()
    }
    try await completion(tmp)
}

func fixTestPaths() {
    let anaconda3 = Path("~/anaconda3/bin").absolute()
    let cargo = Path("~/conda/bin").absolute()
    let path = processInfo.environment["PATH"]!
                + ":\(anaconda3)"
                + ":\(cargo)"
    setenv("PATH", path, 1)
    
}

final class CfiiTester: XCTestCase {
    func test_wheel() async throws {
        
        //fixTestPaths()
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Cffi.self)
        }
    }
}





final class WheelBuilderTests: XCTestCase {
    func test_aiohttp() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Aiohttp.self)
        }
    }
    
    func test_apsw() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Apsw.self)
        }
    }
    
    func test_atom() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Atom.self)
        }
    }
    
    
    
    func test_bitarray() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Bitarray.self)
        }
    }
    
//    func test_() async throws {
//        try await withTemp { tmp in
//            let wheels_dir = tmp + "wheels"
//            try wheels_dir.mkpath()
//            
//            try await build_test(working_dir: tmp, wheel: CiWheels.SQLAlchemy.self)
//        }
//    }
    
    func test_contourpy() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Contourpy.self)
        }
    }
    
    func test_coverage() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Coverage.self)
        }
    }
    
    
    func test_kiwisolver() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Kiwisolver.self)
        }
    }
    
//    func test_lxml() async throws {
//        try await withTemp { tmp in
//            let wheels_dir = tmp + "wheels"
//            try wheels_dir.mkpath()
//            
//            try await build_test(working_dir: tmp, wheel: CiWheels.Lxml.self)
//        }
//    }
    
    func test_materialyoucolor() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Materialyoucolor.self)
        }
    }
    
    func test_matplotlib() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Matplotlib.self)
        }
    }
    
    func test_msgpack() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Msgpack.self)
        }
    }
    
    func test_netifaces() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.SQLAlchemy.self)
        }
    }
    
    func test_pandas() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Pandas.self)
        }
    }
    
    func test_pycryptodome() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.SQLAlchemy.self)
        }
    }
    
    func test_pymunk() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Pymunk.self)
        }
    }
    
    
    func test_SQLAlchemy() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.SQLAlchemy.self)
        }
    }
    
    func test_ujson() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Ujson.self)
        }
    }
    
    func test_zeroconf() async throws {
        try await withTemp { tmp in
            try await build_test(working_dir: tmp, wheel: CiWheels.Zeroconf.self)
        }
    }
}
