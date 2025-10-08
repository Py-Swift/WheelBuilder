//
//  ProcessExtensions.swift
//  WheelBuilder
//
//  Created by CodeBuilder on 07/10/2025.
//
import Foundation
import PlatformInfo
import PathKit

func which(_ name: String) -> Path {
    let proc = Process()
    proc.executableURL = .init(filePath: "/usr/bin/which")
    proc.arguments = [name]
    let pipe = Pipe()
    
    proc.standardOutput = pipe
    var env = ProcessInfo.processInfo.environment
    env["PATH"]?.extendedPath()
    proc.environment = env
    
    try! proc.run()
    proc.waitUntilExit()
    
    guard
        let data = try? pipe.fileHandleForReading.readToEnd(),
        var path = String(data: data, encoding: .utf8)
    else { fatalError() }
    path.strip()
    return .init(path)
}

extension Process {
    
    public static func xcrun(args: String...) throws -> Path {
        let proc = Process()
        proc.executablePath = .xcrun
        proc.arguments = args
        let pipe = Pipe()
        
        proc.standardOutput = pipe
        let env = ProcessInfo.processInfo.environment
        proc.environment = env
        
        try! proc.run()
        proc.waitUntilExit()
        
        guard
            let data = try? pipe.fileHandleForReading.readToEnd(),
            var path = String(data: data, encoding: .utf8)
        else { fatalError() }
        path.strip()
        return .init(path)
    }
    
    public static func get_sdk(sdk: SDK) throws -> Path {
        try xcrun(args: "--show-sdk-path", "--sdk", sdk.description)
    }
    
    public static func get_macos_sdk() throws -> Path {
        try xcrun(args: "--show-sdk-path", "--sdk", "macosx")
    }
    
    public static func cibuildwheel(target: Path, platform: some PlatformProtocol, env: [String: String]? = nil, output: Path) throws {
        let proc = Process()
        proc.executablePath = .cibuildwheel
        
        proc.arguments = [
            target.string,
            "--platform", platform.ci_platform,
            "--archs", platform.ci_archs,
            "--output-dir", output.string
        ]
        
        //proc.currentDirectoryURL = target?.url
        
        proc.environment = env
        
        try proc.run()
        
        proc.waitUntilExit()
    }
    
    public static func cibuildwheel(name: String, platform: some PlatformProtocol, env: [String: String]? = nil, output: Path) throws {
        let proc = Process()
        proc.executablePath = .cibuildwheel
        let arguments: [String] = [
            name,
            "--platform", platform.ci_platform,
            "--archs", platform.ci_archs,
            "--output-dir", output.string,
            "--test-skip"
        ]
        print("cibuildwheel", arguments)
        proc.arguments = arguments
        //proc.currentDirectoryURL = target?.url
        
        proc.environment = env
        
        try proc.run()
        
        proc.waitUntilExit()
    }
    
    public static func pip_download(name: String, output: Path) throws {
        let proc = Process()
        proc.executablePath = .pip3_13
        let arguments: [String] = [
            "download", name, "-d", output.string, "--no-deps", "--no-binary", ":all:"
        ]
        print("pip", arguments)
        proc.arguments = arguments
        //proc.currentDirectoryURL = target?.url
                
        try proc.run()
        
        proc.waitUntilExit()
    }
    
}

public func pip_download(name: String, output: Path) throws -> Path? {
    try Process.pip_download(name: name, output: output)
    
    try output.children().filter({$0.extension == "gz"}).forEach { tar in
        try untar(tar: tar, destination: output)
        try tar.delete()
    }
    return try output.children().first { path in
        //print(name, path, path.lastComponent.hasPrefix(name))
        return path.isDirectory && path.lastComponent.hasPrefix(name)
    }
}

public func untar(tar: Path, destination: Path) throws {
    let proc = Process()
    proc.executablePath = .tar
    let arguments: [String] = [
        "-xzvf", tar.string, "-C", destination.string
    ]
    print("tar", arguments)
    proc.arguments = arguments
    //proc.currentDirectoryURL = target?.url
            
    try proc.run()
    
    proc.waitUntilExit()
}

public func cibuildwheel(target: Path, platform: some PlatformProtocol, env: [String: String]? = nil, output: Path) throws {
    try Process.cibuildwheel(target: target, platform: platform, env: env, output: output)
}
