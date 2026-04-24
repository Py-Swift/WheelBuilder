//
//  Atom.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Atom: CiWheelProtocol {

    public func pre_build(target: Path) async throws {
        // p4a pyproject.toml.patch: add explicit setuptools packages list.
        // Without this, setuptools can't discover the 'atom' package when
        // building from the sdist and produces an empty wheel.
        let pyproject = target + "pyproject.toml"
        guard pyproject.exists else { return }
        var contents = try String(contentsOf: pyproject.url)
        guard !contents.contains("packages = [\"atom\"]") else { return }
        contents = contents.replacingOccurrences(
            of: "  package-data = { atom = [\"py.typed\", \"*.pyi\"] }",
            with: "  package-data = { atom = [\"py.typed\", \"*.pyi\"] }\n  packages = [\"atom\"]"
        )
        try contents.write(to: pyproject.url, atomically: true, encoding: .utf8)
    }

}

