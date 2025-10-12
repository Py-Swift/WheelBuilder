//
//  WheelBuilderCLI.swift
//  WheelBuilder
//
import ArgumentParser
import WheelBuilder
import CiWheels
import PathKit
import Tools
import PyPi_Api
import PipRepo


@main
struct WheelBuilderCLI: AsyncParsableCommand {
    
    static var configuration: CommandConfiguration = .init(
        subcommands: [
            Build.self,
            ActionBuild.self,
            BuildAll.self,
            PipRepo.self
        ]
    )
    
}



extension WheelBuilderCLI {
    
    struct ActionBuild: AsyncParsableCommand {
        
        @Flag var checks: Bool = false
        
        @Argument var output: String
        
        func run() async throws {
            let packages = AnacondaPackages.allCases.compactMap(\.self)
            if checks {
                for pack in packages {
                    if let data = try? await pack.packageData() {
                        if try await compare_versions(target: data) {
                            if let wheel = pack.wheel_package {
                                try await self.build(wheel: wheel)
                            }
                        }
                    }
                }
            } else {
                for wheel in packages.compactMap(\.wheel_package) {
                    try await self.build(wheel: wheel)
                }
            }
        }
    
        func build(wheel: any WheelProtocol.Type) async throws {
            switch wheel {
            case let maturin as MaturinWheelProtocol.Type:
                
                let py_cache = CachedPython()
                try await py_cache.download(version: "3.13", build: "b10")
                try await buildMaturinWheels(wheel: maturin, py_cache: py_cache, wheel_output: .init(output))
                
            case let ciwheel as CiWheelProtocol.Type:
                try await buildCiWheels(wheel: ciwheel, wheel_output: .init(output))
                
            case let library as LibraryWheelProtocol.Type:
                try await buildCiWheels(wheel: library, wheel_output: .init(output))
            default: fatalError()
            }
        }
    }
    
    struct Build: AsyncParsableCommand {
        
        @Argument(transform: {AnacondaPackages(rawValue: $0)}) var package
        
        
        @Argument var output: String
        
        @Option(name: .long) var version: String?
        
        @Flag var all: Bool = false
        
        func run() async throws {
            
            guard let wheel = package??.wheel_package else { fatalError("unsupported package") }
            
            try await self.build(wheel: wheel)
            
        }
        
        func build(wheel: any WheelProtocol.Type) async throws {
            switch wheel {
            case let maturin as MaturinWheelProtocol.Type:
                
                let py_cache = CachedPython()
                try await py_cache.download(version: "3.13", build: "b10")
                try await buildMaturinWheels(
                    wheel: maturin,
                    version: version,
                    py_cache: py_cache,
                    wheel_output: .init(output)
                )
            case let ciwheel as CiWheelProtocol.Type:
                try await buildCiWheels(
                    wheel: ciwheel,
                    version: version,
                    wheel_output: .init(output)
                )
            case let library as LibraryWheelProtocol.Type:
                try await buildCiWheels(
                    wheel: library,
                    wheel_output: .init(output)
                )
            default: fatalError()
            }
        }
        
    }
    
    struct BuildAll: AsyncParsableCommand {
        
        @Argument var output: String
        
        func run() async throws {
            for wheel in AnacondaPackages.allCases.compactMap(\.wheel_package) {
                try await self.build(wheel: wheel)
            }
        }
        
        func build(wheel: any WheelProtocol.Type) async throws {
            switch wheel {
            case let maturin as MaturinWheelProtocol.Type:
                
                let py_cache = CachedPython()
                try await py_cache.download(version: "3.13", build: "b10")
                try await buildMaturinWheels(wheel: maturin, py_cache: py_cache, wheel_output: .init(output))
                
            case let ciwheel as CiWheelProtocol.Type:
                try await buildCiWheels(wheel: ciwheel, wheel_output: .init(output))
                
            case let library as LibraryWheelProtocol.Type:
                try await buildCiWheels(wheel: library, wheel_output: .init(output))
            default: fatalError()
            }
        }
    }
    
    struct PipRepo: AsyncParsableCommand {
        
        @Argument var src_folder: String
        
        @Argument var output: String
        
        func run() async throws {
            let repo = try RepoFolder(root: .init(src_folder))
            try repo.generate_simple(output: .init(output))
        }
        
    }
}


public func compare_versions(target: IphoneosWheelSources.PackageData) async throws -> Bool {
    
    
    let pypi = await PyPi.getApi(for: target.name)
    
    let lastest_version = target.latest_version
    
    if let pypi {
        let needs_build = pypi.info.version > lastest_version
        if needs_build {
            print("\n############# \(target.name) #############")
            print("pypi version: \(pypi.info.version)")
            print("pyswift version: \(lastest_version)")
            //print("wheel build required? \(pypi.info.version > lastest_version)")
            print("\n##########################################")
            print()
        }
        return needs_build
    }
    return false
}
