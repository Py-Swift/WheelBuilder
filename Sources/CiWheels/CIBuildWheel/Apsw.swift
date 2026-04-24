//
//  Apsw.swift
//  WheelBuilder
//
import PlatformInfo
import PathKit
import Tools
import Foundation

@WheelClass
public final class Apsw: CiWheelProtocol {

    public func dependencies_libraries() -> [any LibraryWheelProtocol.Type] {
        [Sqlite3.self]
    }

    public func pre_build(target: Path) async throws {
        guard platform.get_sdk() == .android else { return }

        // apsw's setup.py runs SQLite's ./configure (in fetch.run() triggered by [build] fetch=True)
        // to generate the optional sqlite_cfg.h. When cibuildwheel sets CC to the Android NDK
        // cross-compiler, configure compiles a test binary that can't execute on macOS → fails.
        // cmake_toolchain_file is set by cibuildwheel for all Android builds, so we use it
        // as the guard to skip configure. sqlite_cfg.h is optional — apsw builds fine without it.
        let setupPy = target + "setup.py"
        guard setupPy.exists else { return }
        var src = try String(contentsOf: setupPy.url)

        // NOTE: Swift multiline string strips indentation equal to closing """.
        // Closing """ is at 8 spaces, so 8 spaces are stripped from each line.
        // Actual Python indentation: 12 spaces for `if`, 16 for body → need 20/24 in Swift source.
        let oldConfigure =
            "            if sys.platform != \"win32\":\n" +
            "                write(\"    Running configure to work out SQLite compilation flags\")\n" +
            "                env = os.environ.copy()\n" +
            "                for v in \"CC\", \"CFLAGS\", \"LDFLAGS\":\n" +
            "                    val = sysconfig.get_config_var(v)\n" +
            "                    if val:\n" +
            "                        env[v] = val\n" +
            "                subprocess.check_call([\"./configure\"], cwd=\"sqlite3\", env=env)"

        let newConfigure =
            "            if sys.platform != \"win32\" and \"CMAKE_TOOLCHAIN_FILE\" not in os.environ:\n" +
            "                write(\"    Running configure to work out SQLite compilation flags\")\n" +
            "                env = os.environ.copy()\n" +
            "                for v in \"CC\", \"CFLAGS\", \"LDFLAGS\":\n" +
            "                    val = sysconfig.get_config_var(v)\n" +
            "                    if val:\n" +
            "                        env[v] = val\n" +
            "                subprocess.check_call([\"./configure\"], cwd=\"sqlite3\", env=env)"

        guard src.contains(oldConfigure) else {
            print("Apsw.pre_build: configure block not found in setup.py — skipping patch")
            return
        }
        src = src.replacingOccurrences(of: oldConfigure, with: newConfigure)
        try src.write(to: setupPy.url, atomically: true, encoding: .utf8)
    }

    public func env() throws -> [String : String] {
        var env = base_env()
        env["CIBW_TEST_SKIP"] = "*"
        return env
    }
}
