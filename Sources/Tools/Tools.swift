//
//  Tools.swift
//  WheelBuilder
//
//  Created by CodeBuilder on 07/10/2025.
//
import PathKit
import Foundation

extension PathKit.Path: @unchecked Sendable {}

public extension PathKit.Path {
    static let xcrun: Self = which("xcrun")
    static let xcodebuild: Self = which("xcodebuild")
    static let cibuildwheel: Self = which("cibuildwheel")
    static let python3_13: Self = which("python3.13")
    static let pip3_13: Self = which("pip3.13")
    static let tar: Self = which("tar")
    static let maturin: Self = which("maturin")
    static let patch: Self = which("patch")
    //static let cargo: Self = which("cargo")
}


public extension String {
    mutating func extendedPath() {
        self += (":\(pathsToAdd().joined(separator: ":"))"
                 + ":/Library/Frameworks/Python.framework/Versions/3.13/bin"
                 //+ ":/Users/codebuilder/anaconda3/bin/"
                 //+ ":/Users/codebuilder/.cargo/bin"
        )
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

public func downloadTarFile(url: URL, to folder: Path) async throws {
    //let fn = url.lastPathComponent
    let file: Path = try await URLSession.shared.download(from: url)
    try untar(tar: file, destination: folder)
    try file.delete()
}

public func patch(file: Path, target: Path) async throws {
    let proc = Process()
    
    proc.executablePath = .patch
    
    proc.arguments = [
        "-t", "-d", target.string, "-p1", "-i", file.string
    ]
    
    try proc.run()
    proc.waitUntilExit()
}

public func patch(content: String, fn: String, target: Path) async throws {
    try await withTemp { tmp in
        let patch_file = (tmp + "\(fn).patch")
        try patch_file.write(content)
        try await patch(file: patch_file, target: target)
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

public func downloadURL(url: URL, to dest: Path) async throws -> Path {
    let file: Path = try await URLSession.shared.download(from: url)
    let dest_file = dest + file.lastComponent
    try file.move(dest_file)
    return dest_file
}

public final class CachedPython {
    let root = try! Path.uniqueTemporary()
    //var py_fw: Path?
    var src_ready: Bool = false
    public var version: String = ""
    
    public init() {
        
    }
    
    public func download(version: String, build: String) async throws {
        if src_ready { return }
        try await download_python(version: version, build: build, to: root)
        try await modify_python(path: self.python, version: version)
        src_ready.toggle()
        self.version = version
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
