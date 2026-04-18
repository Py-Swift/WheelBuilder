//
//  Blosc2.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Foundation
import Tools

@WheelClass
public final class Blosc2: CiWheelProtocol {

    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake ninja git"
        env["CIBW_BEFORE_BUILD_IOS"] = [
            "pip install --only-binary=numpy 'scikit-build-core>=0.11.0' 'cython>=3' 'numpy>=2.1'",
            "python -c \"import sys,numpy; open('/tmp/blosc2_cmake_init.cmake','w').write('set(Python_EXECUTABLE \\\"'+sys.executable+'\\\" CACHE FILEPATH \\\"\\\" FORCE)\\nset(Python_NumPy_INCLUDE_DIRS \\\"'+numpy.get_include()+'\\\" CACHE PATH \\\"\\\" FORCE)\\n')\"",
            "MINIEXPR_SRC=/tmp/blosc2_ios_miniexpr",
            "rm -rf $MINIEXPR_SRC",
            "git clone --depth 1 https://github.com/Blosc/miniexpr.git $MINIEXPR_SRC",
            "cd $MINIEXPR_SRC && git fetch --depth 1 origin 37bf6982bf9619036b47f095b7005bc3c87a7447 && git checkout 37bf6982bf9619036b47f095b7005bc3c87a7447",
            "sed -i '' 's/int rc = system(cmd);/int rc = -1; (void)cmd;/' $MINIEXPR_SRC/src/miniexpr.c"
        ].joined(separator: " && ")
        env["CIBW_ENVIRONMENT_IOS"] = [
            "PIP_EXTRA_INDEX_URL=\"https://pypi.anaconda.org/pyswift/simple\"",
            "SKBUILD_CMAKE_ARGS=\"-DFETCHCONTENT_SOURCE_DIR_MINIEXPR=/tmp/blosc2_ios_miniexpr -C /tmp/blosc2_cmake_init.cmake\""
        ].joined(separator: " ")
        env["CIBW_BUILD_FRONTEND"] = "pip; args: --no-build-isolation"
        return env
    }

    public func patches() -> [URL] {
        [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/blosc2-ios.patch"
        ]
    }

    public func apply_patches(target: Path, working_dir: Path) async throws {
        for url in patches() {
            let patch_file = try await downloadURL(url: url, to: working_dir)
            try await git_apply(file: patch_file, target: target)
        }
    }
}
