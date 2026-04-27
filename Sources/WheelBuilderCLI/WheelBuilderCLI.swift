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

extension BuildPlatform: ExpressibleByArgument {}


@main
struct WheelBuilderCLI: AsyncParsableCommand {
    
    static let configuration: CommandConfiguration = .init(
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
        
        //@Option(name: .long, help: "Filter to a specific platform: ios, android. Omit for all platforms.")
        //var platform: BuildPlatform?
        
        func run() async throws {
            let packages = AnacondaPackages.allCases.compactMap(\.self)
            if checks {
                for pack in packages {
                    if let data = try? await pack.packageData() {
                        let platforms = try await compare_versions(target: data)
                        if !platforms.isEmpty, let wheel = pack.wheel_package {
                            let filter: BuildPlatform? = platforms.count == 1 ? platforms[0] : nil
                            try await self.build(wheel: wheel, platform: filter)
                        }
                    } else {
                        if let wheel = pack.wheel_package {
                            try await self.build(wheel: wheel, platform: nil)
                        }
                    }
                }
            } else {
                for wheel in packages.compactMap(\.wheel_package) {
                    try await self.build(wheel: wheel, platform: nil)
                }
            }
        }
    
        func build(wheel: any WheelProtocol.Type, platform: BuildPlatform?) async throws {
            
            switch wheel {
            case let maturin as MaturinWheelProtocol.Type:
                try await buildMaturinWheels(wheel: maturin, platform: platform, wheel_output: .init(output))
            case let ciwheel as CiWheelProtocol.Type:
                try await buildCiWheels(wheel: ciwheel, platform: platform, wheel_output: .init(output))
                
            case let library as LibraryWheelProtocol.Type:
                try await buildCiWheels(wheel: library, platform: platform, wheel_output: .init(output))
            default: fatalError()
            }
        }
    }
    
    struct Build: AsyncParsableCommand {
        
        @Argument(transform: {AnacondaPackages(rawValue: $0)}) var package
        
        @Argument var output: String
        
        @Option(name: .long) var version: String?
        
        @Option(name: .long, help: "Filter to a specific platform: ios, android. Omit for all platforms.")
        var platform: BuildPlatform?
        
        @Flag var all: Bool = false
        
        func run() async throws {
            
            guard let wheel = package??.wheel_package else { fatalError("unsupported package") }
            
            try await self.build(wheel: wheel)
            
        }
        
        func build(wheel: any WheelProtocol.Type) async throws {
            switch wheel {
            case let maturin as MaturinWheelProtocol.Type:
                try await buildMaturinWheels(
                    wheel: maturin,
                    version: version,
                    platform: platform,
                    wheel_output: .init(output)
                )
            case let ciwheel as CiWheelProtocol.Type:
                try await buildCiWheels(
                    wheel: ciwheel,
                    version: version,
                    platform: platform,
                    wheel_output: .init(output)
                )
            case let library as LibraryWheelProtocol.Type:
                try await buildCiWheels(
                    wheel: library,
                    platform: platform,
                    wheel_output: .init(output)
                )
            default: fatalError()
            }
        }
        
    }
    
    struct BuildAll: AsyncParsableCommand {
        
        @Argument var output: String
        
        @Option(name: .long, help: "Filter to a specific platform: ios, android. Omit for all platforms.")
        var platform: BuildPlatform?
        
        func run() async throws {
            for wheel in AnacondaPackages.allCases.compactMap(\.wheel_package) {
                try await self.build(wheel: wheel)
            }
        }
        
        func build(wheel: any WheelProtocol.Type) async throws {
            switch wheel {
            case let maturin as MaturinWheelProtocol.Type:
                try await buildMaturinWheels(wheel: maturin, platform: platform, wheel_output: .init(output))
                
            case let ciwheel as CiWheelProtocol.Type:
                try await buildCiWheels(wheel: ciwheel, platform: platform, wheel_output: .init(output))
                
            case let library as LibraryWheelProtocol.Type:
                try await buildCiWheels(wheel: library, platform: platform, wheel_output: .init(output))
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


public func compare_versions(target: IphoneosWheelSources.PackageData) async throws -> [BuildPlatform] {
    guard let pypi = await PyPi.getApi(for: target.name) else {
        return BuildPlatform.allCases
    }
    
    let pypiVersion = pypi.info.version
    
    let iosLatest = target.files
        .filter { $0.basename.contains("iphoneos") || $0.basename.contains("iphonesimulator") }
        .map(\.version).max()
    let androidLatest = target.files
        .filter { $0.basename.contains("android") }
        .map(\.version).max()
    
    var needed: [BuildPlatform] = []
    if iosLatest.map({ pypiVersion > $0 }) ?? true     { needed.append(.ios) }
    if androidLatest.map({ pypiVersion > $0 }) ?? true { needed.append(.android) }
    
    if !needed.isEmpty {
        let iosStr     = iosLatest     ?? "missing"
        let androidStr = androidLatest ?? "missing"
        print("\n############# \(target.name) #############")
        print("pypi version:    \(pypiVersion)")
        print("ios latest:      \(iosStr)")
        print("android latest:  \(androidStr)")
        print("needs build:     \(needed.map(\.rawValue).joined(separator: ", "))")
        print("##########################################\n")
    }
    
    return needed
}
