//
//  Sqlite3.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@LibraryClass
public final class Sqlite3: LibraryWheelProtocol {

    static let default_version: String = "3.49.1"

    /// SQLite version string → URL integer component: X.Y.Z → X*1000000 + Y*10000 + Z*100
    static func versionInt(_ v: String) -> String {
        let parts = v.split(separator: ".").compactMap { Int($0) }
        let major = parts.count > 0 ? parts[0] : 3
        let minor = parts.count > 1 ? parts[1] : 49
        let patch = parts.count > 2 ? parts[2] : 1
        return String(major * 1_000_000 + minor * 10_000 + patch * 100)
    }

    public var build_target: BuildTarget {
        let v = version ?? Self.default_version
        let vi = Self.versionInt(v)
        return .url("https://www.sqlite.org/2025/sqlite-autoconf-\(vi).tar.gz")
    }

    public func pre_build_library(working_dir: Path) async throws {
        guard platform.get_sdk() == .android else { return }

        let v = version ?? Self.default_version
        let vi = Self.versionInt(v)
        let url = URL(string: "https://www.sqlite.org/2025/sqlite-autoconf-\(vi).tar.gz")!

        try await downloadTarFile(url: url, to: working_dir)

        let srcDir = working_dir + "sqlite-autoconf-\(vi)"

        let ndk = try Process.get_android_ndk()
        let host = Process.android_ndk_host
        let api  = Process.android_api_level
        let binDir = ndk + "toolchains/llvm/prebuilt/\(host)/bin"

        let triple: String
        switch platform.get_arch() {
        case .arm64:  triple = "aarch64-linux-android\(api)"
        case .x86_64: triple = "x86_64-linux-android\(api)"
        }

        let clang  = binDir + "\(triple)-clang"
        let llvmAr = binDir + "llvm-ar"

        // Compile sqlite3.c → sqlite3.o
        let objFile = srcDir + "sqlite3.o"
        let compileProc = Process()
        compileProc.executableURL = clang.url
        compileProc.arguments = [
            "-O2", "-c",
            (srcDir + "sqlite3.c").string,
            "-o", objFile.string,
            "-DSQLITE_THREADSAFE=1",
            "-DSQLITE_ENABLE_FTS5",
        ]
        try compileProc.run()
        compileProc.waitUntilExit()
        guard compileProc.terminationStatus == 0 else {
            throw NSError(domain: "Sqlite3Build", code: Int(compileProc.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "sqlite3.c compile failed (exit \(compileProc.terminationStatus))"])
        }

        // Archive → libsqlite3.a
        let libFile = srcDir + "libsqlite3.a"
        let arProc = Process()
        arProc.executableURL = llvmAr.url
        arProc.arguments = ["rcs", libFile.string, objFile.string]
        try arProc.run()
        arProc.waitUntilExit()
        guard arProc.terminationStatus == 0 else {
            throw NSError(domain: "Sqlite3Build", code: Int(arProc.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "llvm-ar failed (exit \(arProc.terminationStatus))"])
        }

        // Install
        let incDir = include_dir()
        let libDir = lib_dir()
        try? incDir.mkpath()
        try? libDir.mkpath()

        try (srcDir + "sqlite3.h").copy(incDir + "sqlite3.h")
        try libFile.copy(libDir + "libsqlite3.a")
    }

    public func build_library_platform(working_dir: Path) async throws {}

    public func post_build_library(working_dir: Path) async throws {}

    public func cflag_includes() -> [Env.CFlags.Value] {
        guard platform.get_sdk() == .android else { return [] }
        return [.include(include_dir())]
    }

    public func ldflag_libraries() -> [Env.LDFlags.Value] {
        guard platform.get_sdk() == .android else { return [] }
        return [.library(lib_dir())]
    }
}
