import PathKit


public protocol PlatformProtocol {
    static var sdk: SDK { get }
    static var arch: Arch { get }
    
    var cflags: Env.CFlags { get }
    var ldflags: Env.LDFlags { get }
}

public extension PlatformProtocol {
    var ci_archs: String {
        "\(Self.arch)_\(Self.sdk)"
    }
    
    var ci_platform: String { "ios" }
    
    var wheel_file_platform: String { "ios_13_0_\(Self.arch)_\(Self.sdk)"}
}



