//
//  Bcrypt.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation

@WheelClass
public final class Bcrypt: CiWheelProtocol {
    
    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake rustc cargo"
        // Ensure the rustup-managed cargo/rustc is used rather than any
        // system-installed Rust (e.g. Homebrew) that lacks Android targets.
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            env["CARGO"] = "\(home)/.cargo/bin/cargo"
            env["RUSTC"] = "\(home)/.cargo/bin/rustc"
        }
        return env
    }

    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        // p4a: depends = ['openssl', 'cffi']
        guard platform.get_sdk() == .android else { return [] }
        return [Openssl.self, Libffi.self]
    }

    public func patches() -> [URL] {
        [
            //"https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/bcrypt.patch"
        ]
    }
}
