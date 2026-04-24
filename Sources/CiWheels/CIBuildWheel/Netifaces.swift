//
//  Netifaces.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Netifaces: CiWheelProtocol {

    public func pre_build(target: Path) async throws {
        guard platform.get_sdk() == .android else { return }
        // p4a fix-build.patch: test_build links and would try to run executables
        // during cross-compilation, which fails. Change link=True default to False
        // so feature detection uses compile-only checks.
        let setup = target + "setup.py"
        guard setup.exists else { return }
        var contents = try String(contentsOf: setup.url)
        contents = contents.replacingOccurrences(
            of: "def test_build(self, contents, link=True, execute=False,",
            with: "def test_build(self, contents, link=False, execute=False,"
        )
        try contents.write(to: setup.url, atomically: true, encoding: .utf8)
    }

}
