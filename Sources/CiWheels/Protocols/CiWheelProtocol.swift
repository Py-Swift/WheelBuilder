import Foundation
import PlatformInfo
import Tools
import PathKit


public protocol CiWheelProtocol: WheelProtocol {
    
    init(version: String?, platform: any PlatformProtocol, root: Path)
    
    static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self
    
    func build_wheel(target: Path, platform: any PlatformProtocol, output: Path) async throws
    
    
}


public extension CiWheelProtocol {
    
    static func new(version: String?, platform: any PlatformProtocol, root: Path) -> Self {
        .init(version: version, platform: platform, root: root)
    }
    
    func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        []
    }
    
    func patches() -> [URL] {[]}

    func urls() -> [URL] {[]}
    func pre_build(target: Path) async throws {}
    func _build_wheel(output: Path) async throws -> Bool { false }
    
//    func get_cflags(platform: any PlatformProtocol) -> Env.CFlags {
//        platform.cflags
//    }
//    
//    func get_ldflags(platform: any PlatformProtocol) -> Env.LDFlags {
//        platform.ldflags
//    }
    
    func get_cflags() -> Env.CFlags {
        let flags = platform.cflags
        for dep in dependencies_libraries() {
            let lib = dep.new(version: nil, platform: platform, root: root)
            flags.append(contentsOf: lib.cflag_includes())
        }
        return flags
    }
    
    func get_ldflags() -> Env.LDFlags {
        let flags = platform.ldflags
        for dep in dependencies_libraries() {
            let lib = dep.new(version: nil, platform: platform, root: root)
            flags.append(contentsOf: lib.ldflag_libraries())
        }
        return flags
    }
    
    
    func base_env() -> [String:String] {
        [
            "CFLAGS": get_cflags().description,
            "LDFLAGS": get_ldflags().description
        ] + processInfo.environment
    }
    
    func env() throws -> [String : String] {
        base_env()
    }
}

public extension CiWheelProtocol {
    func build_wheel(target: Path, platform: any PlatformProtocol, output: Path) async throws {
        try await pre_build(target: target)
        if try await _build_wheel(output: output) { return }
        
        try await Process.cibuildwheel(
            target: target,
            platform: platform,
            env: env(),
            output: output
        )
        
    }
    
    func build_wheel(working_dir: Path, version: String? = nil, wheels_dir: Path) async throws {
        try await pre_build(target: working_dir)
        if try await _build_wheel(output: working_dir) { return }
        switch build_target {
        case .local(let path):
            try await Process.cibuildwheel(
                target: path,
                platform: platform,
                env: env(),
                output: wheels_dir
            )
        case .pypi(let pypi):
            if let pypi_folder = try pip_download(name: pypi, version: version, output: working_dir) {
                
                try await apply_patches(target: pypi_folder, working_dir: working_dir)
                
                try await Process.cibuildwheel(
                    target: pypi_folder,
                    platform: platform,
                    env: env(),
                    output: wheels_dir
                )
                try? pypi_folder.delete()
                
            }
        case .url(_):
            break
        }
        
        
    }
    
}
