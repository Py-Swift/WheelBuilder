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
            // cffi requires compiling a C extension (_cffi_backend.c) that needs ffi.h from
            // libffi, which is not available in the iOS cross-build environment.
            // cffi is a runtime dependency only — maturin's build process does not import it.
            // Use --skip-dependency-check to let python -m build proceed without cffi installed.
            // setuptools is pure Python and installs fine; maturin compiles OK for iOS targets.
            env["CIBW_BEFORE_BUILD"] = "pip install maturin setuptools"
            env["CIBW_BUILD_FRONTEND"] = "build;args: --no-isolation --skip-dependency-check"
        }
        return env
    }
    
    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [Openssl.self]
    }
    

}
