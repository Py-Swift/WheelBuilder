import PathKit
import PlatformInfo
import Tools
import Foundation

@LibraryClass
public final class Ffmpeg: CiWheelProtocol {

    static let default_version: String = "8.0.1"

    public var build_target: BuildTarget {
        let v = version ?? Self.default_version
        return .url("https://www.ffmpeg.org/releases/ffmpeg-\(v).tar.xz")
    }

    public func build_wheel(working_dir: Path, version: String? = nil, wheels_dir: Path) async throws {
        guard platform.get_sdk() == .android else { return }

        let v = version ?? Self.default_version
        let url = URL(string: "https://www.ffmpeg.org/releases/ffmpeg-\(v).tar.xz")!

        let ndk = try Process.get_android_ndk()
        let host = Process.android_ndk_host
        let api  = Process.android_api_level
        let binDir = ndk + "toolchains/llvm/prebuilt/\(host)/bin"
        let sysroot = ndk + "toolchains/llvm/prebuilt/\(host)/sysroot"

        let triple: String
        let archFlag: String
        let extraFlags: [String]

        switch platform.get_arch() {
        case .arm64:
            triple = "aarch64-linux-android"
            archFlag = "aarch64"
            extraFlags = []
        case .x86_64:
            triple = "x86_64-linux-android"
            archFlag = "x86"
            extraFlags = ["--disable-asm"]
        }

        let clangTriple = "\(triple)\(api)"
        let crossPrefix = (binDir + "\(clangTriple)-").string

        // Use an arch-specific work directory so arm64 and x86_64 builds don't share .o files
        let archWorkDir = working_dir + archFlag
        try archWorkDir.mkpath()
        try await downloadTarFile(url: url, to: archWorkDir)
        let srcDir = archWorkDir + "ffmpeg-\(v)"

        try await patch(content: ffmpeg_configure_patch, fn: "configure", target: srcDir)

        // FFmpeg 8.0.1+ already ships compat/android/binder.c; only apply the backport on older releases
        if !(srcDir + "compat/android/binder.c").exists {
            try await withTemp { tmpDir in
                let patchFile = tmpDir + "android15.patch"
                try patchFile.write(ffmpeg_android15_patch)
                try await git_apply(file: patchFile, target: srcDir)
            }
        }

        let env: [String: String] = [
            "PATH": "\(binDir.string):/usr/bin:/bin",
            "CC":     (binDir + "\(clangTriple)-clang").string,
            "CXX":    (binDir + "\(clangTriple)-clang++").string,
            "AR":     (binDir + "llvm-ar").string,
            "RANLIB": (binDir + "llvm-ranlib").string,
            "NM":     (binDir + "llvm-nm").string,
            "STRIP":  (binDir + "llvm-strip").string,
        ]

        let configureArgs: [String] = [
            "--enable-jni",
            "--enable-mediacodec",
            "--disable-symver",
            "--disable-doc",
            "--enable-filter=aresample,resample,crop,adelay,volume,scale",
            "--enable-protocol=file,http,hls,udp,tcp",
            "--enable-small",
            "--enable-hwaccels",
            "--enable-pic",
            "--disable-static",
            "--disable-debug",
            "--enable-shared",
            "--enable-parser=aac,ac3,h261,h264,mpegaudio,mpeg4video,mpegvideo,vc1",
            "--enable-decoder=aac,h264,mpeg4,mpegvideo",
            "--enable-muxer=h264,mov,mp4,mpeg2video",
            "--enable-demuxer=aac,h264,m4v,mov,mpegvideo,vc1,rtsp",
            "--target-os=android",
            "--enable-cross-compile",
            "--cross-prefix=\(crossPrefix)",
            "--arch=\(archFlag)",
            "--strip=\((binDir + "llvm-strip").string)",
            "--nm=\((binDir + "llvm-nm").string)",
            "--sysroot=\(sysroot.string)",
            "--enable-neon",
            "--prefix=\(srcDir.string)",
        ] + extraFlags

        try runProcess(
            executable: srcDir + "configure",
            args: configureArgs,
            env: env,
            cwd: srcDir,
            domain: "FfmpegConfigure"
        )

        let cpuCount = ProcessInfo.processInfo.processorCount
        try runProcess(
            executable: Path("/usr/bin/make"),
            args: ["-j", "\(cpuCount)"],
            env: env,
            cwd: srcDir,
            domain: "FfmpegMake"
        )

        try runProcess(
            executable: Path("/usr/bin/make"),
            args: ["install"],
            env: env,
            cwd: srcDir,
            domain: "FfmpegInstall"
        )

        let libsDir    = srcDir + "lib"
        let includeDir = srcDir + "include"
        let ffmpegBin  = srcDir + "ffmpeg"
        if ffmpegBin.exists {
            try ffmpegBin.copy(libsDir + "libffmpegbin.so")
        }

        try await packageWheel(libsDir: libsDir, includeDir: includeDir, version: v, wheels_dir: wheels_dir)
    }

}

extension Ffmpeg {

    private func runProcess(executable: Path, args: [String], env: [String: String], cwd: Path, domain: String) throws {
        let proc = Process()
        proc.executableURL = executable.url
        proc.arguments = args
        proc.environment = env
        proc.currentDirectoryURL = cwd.url
        try proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else {
            throw NSError(
                domain: domain,
                code: Int(proc.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "\(domain) failed (exit \(proc.terminationStatus))"]
            )
        }
    }

    private func packageWheel(libsDir: Path, includeDir: Path, version: String, wheels_dir: Path) async throws {
        let abiTag: String
        switch platform.get_arch() {
        case .arm64:  abiTag = "arm64_v8a"
        case .x86_64: abiTag = "x86_64"
        }

        let api = Process.android_api_level
        let platformTag = "android_\(api)_\(abiTag)"
        let wheelName = "ffmpeg-\(version)-py3-none-\(platformTag).whl"

        try await withTemp { stagingDir in
            let pkgDir        = stagingDir + "ffmpeg"
            let dotLibsDir    = pkgDir + ".libs"
            let dotIncludesDir = pkgDir + ".includes"
            let distInfoDir   = stagingDir + "ffmpeg-\(version).dist-info"

            try pkgDir.mkpath()
            try dotLibsDir.mkpath()
            try distInfoDir.mkpath()

            try (pkgDir + "__init__.py").write("")

            let soFiles = try libsDir.children().filter { $0.`extension` == "so" }
            for so in soFiles {
                try so.copy(dotLibsDir + so.lastComponent)
            }

            if includeDir.exists {
                try FileManager.default.copyItem(
                    atPath: includeDir.string,
                    toPath: dotIncludesDir.string
                )
            }

            let metadata = """
                Metadata-Version: 2.1
                Name: ffmpeg
                Version: \(version)
                Summary: FFmpeg shared libraries for Android
                Home-page: https://ffmpeg.org
                License: LGPL-2.1
                Platform: Android
                """
            try (distInfoDir + "METADATA").write(metadata)

            let wheel = """
                Wheel-Version: 1.0
                Generator: WheelBuilder
                Root-Is-Purelib: false
                Tag: py3-none-\(platformTag)
                """
            try (distInfoDir + "WHEEL").write(wheel)

            try (distInfoDir + "RECORD").write("")

            try wheels_dir.mkpath()
            let wheelPath = wheels_dir + wheelName

            let zip = Process()
            zip.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            zip.arguments = ["-r", wheelPath.string, "ffmpeg", "ffmpeg-\(version).dist-info"]
            zip.currentDirectoryURL = stagingDir.url
            try zip.run()
            zip.waitUntilExit()
            guard zip.terminationStatus == 0 else {
                throw NSError(
                    domain: "FfmpegPackage",
                    code: Int(zip.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: "zip failed (exit \(zip.terminationStatus))"]
                )
            }
        }
    }

}
