//
//  Tools.swift
//  WheelBuilder
//
//  Created by CodeBuilder on 07/10/2025.
//
import PathKit
import Foundation

public extension PathKit.Path {
    static let xcrun: Self = which("xcrun")
    static let cibuildwheel: Self = which("cibuildwheel")
    static let pip3_13: Self = which("pip3.13")
    static let tar: Self = which("tar")
    static let maturin: Self = which("maturin")
    //static let cargo: Self = which("cargo")
}


public extension String {
    mutating func extendedPath() {
        self += (":\(pathsToAdd().joined(separator: ":"))" + ":/Library/Frameworks/Python.framework/Versions/3.13/bin:/Users/codebuilder/anaconda3/bin/" + ":/Users/codebuilder/.cargo/bin")
    }
    mutating func strip() {
        self.removeLast(1)
    }
}

extension Process {
    public var executablePath: Path? {
        get {
            if let executableURL {
                return .init(executableURL.absoluteString)
            }
            return nil
        }
        set {
            executableURL = newValue?.url
        }
    }
}

fileprivate func pathsToAdd() -> [String] {[
    "/usr/local/bin",
    "/opt/homebrew/bin"
]}

public func withTemp(completion: @escaping (Path)async throws -> Void) async throws {
    let tmp = try Path.uniqueTemporary()
    defer {
        try! tmp.delete()
    }
    try await completion(tmp)
}


extension URL: Swift.ExpressibleByStringInterpolation {
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value)!
    }
}

extension URLSession {
    public func download(from url: URL, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> Path {
        let (file, _) = try await download(from: url)
        
        return Path(file.path())
    }
}


public func download_python(version: String, build: String, to folder: Path) async throws {
    let fn = "Python-\(version)-iOS-support.\(build).tar.gz"
    let url: URL = "https://github.com/beeware/Python-Apple-support/releases/download/\(version)-\(build)/\(fn)"
    let file: Path = try await URLSession.shared.download(from: url)
    try untar(tar: file, destination: folder)
    try file.delete()
}

public func modify_python(path: Path, version: String) async throws {
    let sim_fw = path + "ios-arm64_x86_64-simulator"
    let sim_arm64 = path + "ios-arm64-simulator"
    let sim_x86_64 = path + "ios-x86_64-simulator"
    print(try path.children().map(\.self))
    try sim_fw.copy(sim_arm64)
    try sim_fw.copy(sim_x86_64)
    
    try (sim_arm64 + "lib/python\(version)/_sysconfigdata__ios_x86_64-iphonesimulator.py").delete()
    try (sim_x86_64 + "lib/python\(version)/_sysconfigdata__ios_arm64-iphonesimulator.py").delete()
    
}

public final class CachedPython {
    let root = try! Path.uniqueTemporary()
    //var py_fw: Path?
    
    public init() {
        
    }
    
    public func download(version: String, build: String) async throws {
        //Task {[unowned self] in
            try await download_python(version: version, build: build, to: root)
            try await modify_python(path: self.python, version: version)
        //}
    }
    
    deinit {
        try! root.delete()
    }
    
    public var python: Path {
        root + "Python.xcframework"
    }
    
    public var arm64: Path {
        python + "ios-arm64"
    }
    
    public var arm64_x86_64_simulator: Path {
        python + "ios-arm64_x86_64-simulator"
    }
    
    public var arm64_simulator: Path {
        python + "ios-arm64-simulator"
    }
    
    public var x86_64_simulator: Path {
        python + "ios-x86_64-simulator"
    }
}
