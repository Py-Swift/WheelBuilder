import PathKit
import Foundation

public protocol PlatformProtocol {
    static var sdk: SDK { get }
    static var arch: Arch { get }
    
    var cflags: Env.CFlags { get }
    var ldflags: Env.LDFlags { get }
}

public extension PlatformProtocol {
    var ci_archs: String {
        switch sdk {
        case .android:
            switch arch {
            case .arm64:
                "arm64_v8a"
            case .x86_64:
                "x86_64"
            }
        default:
            "\(Self.arch)_\(Self.sdk)"
        }
    }
    
    var arch: Arch { Self.arch }
    
    var sdk: SDK { Self.sdk }
    
    
    
    var arch_sdk: String { "\(Self.arch)_\(Self.sdk)"}
    
    var sdk_arch: String { "\(Self.sdk)_\(Self.arch)"}
    
    var ci_platform: String {
        switch sdk {
        case .iphoneos, .iphonesimulator:
            "ios"
        case .macos:
            fatalError("no macos support")
        case .android:
            "android"
        }
    }
    
    var wheel_file_platform: String { "ios_13_0_\(Self.arch)_\(Self.sdk)"}
}



