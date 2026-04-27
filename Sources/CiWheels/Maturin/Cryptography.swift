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
            // CIBW_BEFORE_BUILD runs inside the iOS cross-build venv whose pip has iOS
            // platform tags. Installing maturin works (maturin's Rust build compiles fine
            // for iOS), but cffi has a C extension (_cffi_backend.c) that requires ffi.h
            // which is not available in the iOS SDK — so "pip install cffi" would fail.
            //
            // Instead, we download the macOS arm64 binary wheel for cffi and install it
            // without platform checks. The venv's Python interpreter IS a macOS Python, so
            // the macOS cffi wheel is fully functional at runtime for HOST-side scripts like
            // build_openssl.py. We also add setuptools the same way.
            //
            // --skip-dependency-check prevents python -m build --no-isolation from trying
            // to re-install cffi/setuptools via the iOS-tagged pip (which would fail again).
            // pip install --no-deps still checks platform tags (rejects macOS wheel in the
            // iOS-tagged venv). Bypass pip entirely: extract the wheel (it's just a zip)
            // directly into site-packages. The venv Python IS a macOS Python so the macOS
            // cffi .so works at runtime.
            let beforeBuild = [
                "pip install maturin setuptools pycparser",
                "pip download cffi --platform macosx_14_0_arm64 --python-version 313 --only-binary :all: -d /tmp/cffi_wheels",
                "python -c 'import sys, zipfile, glob; sp = next(p for p in sys.path if \"site-packages\" in p); whl = glob.glob(\"/tmp/cffi_wheels/cffi*.whl\")[0]; zipfile.ZipFile(whl).extractall(sp)'",
                // pyo3 requires _sysconfigdata*.py in PYO3_CROSS_LIB_DIR but the
                // Python-Apple-support xcframework lib dir doesn't include one.
                // Synthesise it from the cross-venv's sysconfig so pyo3-build-config
                // can find it and extract the Python version / ABI information.
                "python3 -c \"import sysconfig, os; libdir=sysconfig.get_config_var('LIBDIR'); vars=sysconfig.get_config_vars(); open(os.path.join(libdir,'_sysconfigdata__ios.py'),'w').write('build_time_vars='+repr(vars))\""
            ].joined(separator: " && ")
            env["CIBW_BEFORE_BUILD"] = beforeBuild
            env["CIBW_BUILD_FRONTEND"] = "build;args: --no-isolation --skip-dependency-check"
        }
        return env
    }
    
    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [Openssl.self]
    }
    

}
