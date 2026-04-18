//
//  Pendulum.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass()
public final class Pendulum: CiWheelProtocol {

    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake rustc cargo"
        
        let ios_sdkroot = try platform.sdk_root()
        
        let cargo_target = [
            "-C link-arg=-isysroot", "-C link-arg=\(ios_sdkroot)",
            "-C link-arg=-arch", "-C link-arg=\(platform.get_arch())",
            //"-C link-arg=-L", "-C link-arg=\(py_cache.python)",
            "-C link-arg=-undefined", "-C link-arg=dynamic_lookup"
        ]
        
        env["OSX_SDKROOT"] = try Process.get_macos_sdk().string
        env["IOS_SDKROOT"] = ios_sdkroot.string
        
        
        //env["PYTHONDIR"] = py_cache.python.string
        //env["PYO3_CROSS_PYTHON_VERSION"] = py_cache.version
        
        env["SDKROOT"] = ios_sdkroot.string
        //env["PYO3_CROSS_LIB_DIR"] = platform.py_maturin_framework(cached: py_cache).string
        //env["OPENSSL_DIR"] = "/usr/local/Cellar/openssl@3/3.5.2"
        env[platform.cargo_target_key] = cargo_target.joined(separator: " ")
        
        return env
    }

}

