//
//  Cryptography.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Cryptography: MaturinWheelProtocol {
   
    
    public func env() throws -> [String : String] {
        var env = try maturin_env()
        env["OPENSSL_DIR"] = (root + "openssl/\(platform.sdk_arch)").string
        if platform.get_sdk() != .android {
            // CIBW_BEFORE_BUILD runs with the HOST (macOS) pip, so cffi installs as a macOS
            // binary wheel (not cross-compiled for iOS). We then use --skip-dependency-check
            // to prevent python -m build from re-installing cffi via the iOS-tagged pip
            // (which would try to compile _cffi_backend.c for iOS, failing at ffi.h not found).
            // With cffi installed (macOS binary) and re-installation skipped, cargo's
            // build_openssl.py can import cffi successfully on the HOST macOS machine.
            env["CIBW_BEFORE_BUILD"] = "pip install maturin cffi setuptools"
            env["CIBW_BUILD_FRONTEND"] = "build;args: --no-isolation --skip-dependency-check"
        }
        return env
    }
    
    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [Openssl.self]
    }
    

}
