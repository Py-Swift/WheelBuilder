import Foundation
import PlatformInfo
import Tools
import PathKit


public protocol CiWheelProtocol: WheelProtocol {
    
    static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self
    
    func build_wheel(target: Path, platform: any PlatformProtocol, output: Path) async throws
    
    
}


public extension CiWheelProtocol {
    
    func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        []
    }
    
    func patches() -> [URL] {[]}

    func urls() -> [URL] {[]}
    func pre_build(platform: any PlatformProtocol, target: Path) async throws {}
    func _build_wheel(platform: any PlatformProtocol, output: Path) async throws -> Bool { false }
    
    func get_cflags(platform: any PlatformProtocol) -> Env.CFlags {
        platform.cflags
    }
    
    func get_ldflags(platform: any PlatformProtocol) -> Env.LDFlags {
        platform.ldflags
    }
    
    func base_env(platform: any PlatformProtocol) -> [String:String] {
        [
            "CFLAGS": get_cflags(platform: platform).description,
            "LDFLAGS": get_ldflags(platform: platform).description
        ] + processInfo.environment
    }
    
    func env(platform: any PlatformProtocol) throws -> [String : String] {
        base_env(platform: platform)
    }
}

public extension CiWheelProtocol {
    func build_wheel(target: Path, platform: any PlatformProtocol, output: Path) async throws {
        try await pre_build(platform: platform, target: target)
        if try await _build_wheel(platform: platform, output: output) { return }
        
        try await Process.cibuildwheel(
            target: target,
            platform: platform,
            env: env(platform: platform),
            output: output
        )
        
    }
    
    func build_wheel(working_dir: Path, wheels_dir: Path) async throws {
        try await pre_build(platform: platform, target: working_dir)
        if try await _build_wheel(platform: platform, output: working_dir) { return }
        switch build_target {
        case .local(let path):
            try await Process.cibuildwheel(
                target: path,
                platform: platform,
                env: env(platform: platform),
                output: wheels_dir
            )
        case .pypi(let pypi):
            if let pypi_folder = try pip_download(name: pypi, output: working_dir) {
                try await apply_patches(target: pypi_folder, working_dir: working_dir)
                
                //print(working_dir.map(\.self))
                try await Process.cibuildwheel(
                    target: pypi_folder,
                    platform: platform,
                    env: env(platform: platform),
                    output: wheels_dir
                )
                try? pypi_folder.delete()
            }
        case .url(let url):
            break
        }
        
        
    }
    
}
