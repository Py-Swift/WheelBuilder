#!/usr/bin/env python3
"""Build wheels for Kivy, thorvg-cython (GPU/ANGLE), and kivy-thor.

Run from a directory containing the sibling repos:
    cd <root>              ← has kivy/, thorvg-cython/, kivy-thor/
    python kivy-thor/scripts/build_kt.py all macos

Expected layout at CWD:
    kivy/               ← Kivy source
    thorvg-cython/      ← thorvg-cython source
    kivy-thor/          ← this repo
    wheelhouse/         ← created automatically for output wheels
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from enum import Enum
from pathlib import Path


THIS_FILE = Path(__file__).resolve()


# ── Platform ──────────────────────────────────────────────────────────────────

class Platform(Enum):
    MACOS   = "macos"
    IOS     = "ios"
    ANDROID = "android"
    # LINUX   = "linux"     # future
    # WINDOWS = "windows"   # future


# ── Paths ─────────────────────────────────────────────────────────────────────

@dataclass
class Paths:
    """All configurable paths.  Resolved once from CLI args / env vars."""
    wheelhouse:          Path
    kivy_src:            Path
    thorvg_cython_src:   Path
    kivy_thor_src:       Path
    pyjnius_src:         Path
    pymunk_src:          Path
    cffi_src:            Path
    kivy_deps:           Path
    ios_kivy_deps:       Path
    angle_lib_dir:       Path
    angle_include_dir:   Path
    thorvg_capi_include: Path
    android_ndk:         Path

    @property
    def repair_library_path(self) -> Path:
        return self.kivy_deps / "dist" / "Frameworks"


# Build settings
PYTHON_VERSION  = "cp313-*"
IOS_ARCHS       = "arm64_iphoneos arm64_iphonesimulator x86_64_iphonesimulator"
ANDROID_ARCHS   = "arm64_v8a x86_64"


# ── Helpers ───────────────────────────────────────────────────────────────────

def log(msg: str) -> None:
    print(f"==> {msg}", flush=True)


def run(cmd: list[str | Path], *, env: dict | None = None, cwd: Path | None = None) -> None:
    merged = {**os.environ, **(env or {})}
    merged = {k: str(v) for k, v in merged.items()}
    subprocess.run([str(c) for c in cmd], check=True, env=merged, cwd=cwd)


def capture(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True).strip()


def sdkroot(platform: Platform) -> str:
    sdk = "macosx" if platform is Platform.MACOS else "iphoneos"
    return capture(["xcrun", "--sdk", sdk, "--show-sdk-path"])


def xcode_toolchain_bin() -> str:
    return str(Path(capture(["xcrun", "-f", "clang"])).parent)


def _cibuildwheel(
    source: Path,
    platform: Platform,
    paths: Paths,
    *,
    env: dict | None = None,
    archs: str | None = None,
) -> None:
    cmd: list[str | Path] = ["cibuildwheel", "--platform", platform.value]
    if archs:
        cmd += ["--archs", archs]
    cmd += ["--output-dir", paths.wheelhouse, source]
    base: dict[str, str] = {"CIBW_BUILD": PYTHON_VERSION}
    if platform is not Platform.ANDROID:
        base["SDKROOT"] = sdkroot(platform)
    base.update(env or {})
    run(cmd, env=base)


# ── Base builder ──────────────────────────────────────────────────────────────

class Builder:
    name: str
    wheel_prefix: str  # e.g. "Kivy-" or "thorvg_cython-"

    def __init__(self, paths: Paths) -> None:
        self.p = paths

    def _has_wheel(self, platform: Platform) -> bool:
        """True if a matching wheel already exists in the wheelhouse."""
        tag = {Platform.MACOS: "macosx", Platform.IOS: "ios", Platform.ANDROID: "android"}[platform]
        return any(self.p.wheelhouse.glob(f"{self.wheel_prefix}*{tag}*.whl"))

    def build(self, platform: Platform | str) -> None:
        if isinstance(platform, str):
            platform = Platform(platform)
        self.p.wheelhouse.mkdir(parents=True, exist_ok=True)
        if platform is Platform.MACOS:
            self.build_macos()
        elif platform is Platform.IOS:
            self.build_ios()
        elif platform is Platform.ANDROID:
            self.build_android()
        else:
            raise NotImplementedError(f"{platform.value} not yet supported")

    def build_macos(self) -> None:
        raise NotImplementedError

    def build_ios(self) -> None:
        raise NotImplementedError

    def build_android(self) -> None:
        raise NotImplementedError


# ── Kivy ──────────────────────────────────────────────────────────────────────

class Kivy(Builder):
    name = "kivy"
    wheel_prefix = "kivy-"

    # Must match SDL_VER in build_android_libraries.sh
    SDL3_VERSION = "3.2.22"

    def build_macos(self) -> None:
        if self._has_wheel(Platform.MACOS):
            log("Kivy macOS wheel already exists, skipping (delete it to rebuild).")
            return
        log("Building Kivy macOS dependencies...")
        run(["bash", "./tools/build_macos_dependencies.sh"], cwd=self.p.kivy_src)

        log("Building Kivy macOS wheel...")
        repair_path = self.p.repair_library_path
        repair = (
            f"DYLD_LIBRARY_PATH={repair_path} "
            "delocate-listdeps {wheel} && "
            f"DYLD_LIBRARY_PATH={repair_path} "
            "delocate-wheel --require-archs {delocate_archs} -w {dest_dir} {wheel}"
        )
        _cibuildwheel(self.p.kivy_src, Platform.MACOS, self.p, env={
            "USE_SDL3": "1",
            "KIVY_DEPS_ROOT": str(self.p.kivy_deps),
            "REPAIR_LIBRARY_PATH": str(repair_path),
            "CIBW_ENVIRONMENT": "MACOSX_DEPLOYMENT_TARGET=10.15",
            "CIBW_REPAIR_WHEEL_COMMAND_MACOS": repair,
        })
        log("Kivy macOS done.")

    def build_ios(self) -> None:
        if self._has_wheel(Platform.IOS):
            log("Kivy iOS wheels already exist, skipping (delete them to rebuild).")
            return
        log("Building Kivy iOS dependencies...")
        run(["bash", "./tools/build_ios_dependencies.sh"], cwd=self.p.kivy_src)

        log("Building Kivy iOS wheels...")
        _cibuildwheel(self.p.kivy_src, Platform.IOS, self.p, archs=IOS_ARCHS, env={
            "USE_SDL3": "1",
            "KIVY_DEPS_ROOT": str(self.p.ios_kivy_deps),
        })

        log("Patching Kivy iOS wheels with xcframeworks...")
        run(["python3", self.p.kivy_src / "tools" / "add-ios-frameworks.py",
             self.p.wheelhouse],
            env={"KIVY_DEPS_ROOT": str(self.p.ios_kivy_deps)})
        log("Kivy iOS done.")

    def build_android(self) -> None:
        if self._has_wheel(Platform.ANDROID):
            log("Kivy Android wheels already exist, skipping (delete them to rebuild).")
            return

        log("Building SDL3 libraries for Android from source...")
        build_libs = self.p.kivy_thor_src / "scripts" / "build_android_libraries.sh"
        android_output = self.p.kivy_thor_src / "scripts" / "android_output"
        run(
            ["bash", build_libs, str(android_output)],
            env={"ANDROID_NDK_HOME": str(self.p.android_ndk)},
            cwd=self.p.kivy_thor_src / "scripts",
        )

        log("Building kivy-sdl3 Android wheels...")
        self._build_kivy_sdl3_wheels(android_output)

        log("Building Kivy Android wheels...")
        _cibuildwheel(self.p.kivy_src, Platform.ANDROID, self.p, archs=ANDROID_ARCHS, env={
            "USE_SDL3": "1",
            "ANDROID_NDK_HOME": str(self.p.android_ndk),
            "PIP_FIND_LINKS": str(self.p.wheelhouse),
            "CIBW_ENVIRONMENT_ANDROID": " ".join([
                "ANDROID_API_LEVEL=21",
                f"PIP_FIND_LINKS={self.p.wheelhouse}",
            ]),
            "CIBW_REPAIR_WHEEL_COMMAND_ANDROID": "cp {wheel} {dest_dir}/",
        })
        log("Kivy Android done.")

    def _build_kivy_sdl3_wheels(self, android_output: Path) -> None:
        """Package per-ABI SDL3 .so files into kivy-sdl3 wheels."""
        import shutil, zipfile, email.message

        version = self.SDL3_VERSION
        api = 21
        abis = ["arm64-v8a", "x86_64"]
        libs = ["SDL3", "SDL3_image", "SDL3_mixer", "SDL3_ttf"]

        for abi in abis:
            whl_abi = abi.replace("-", "_")
            tag = f"cp313-cp313-android_{api}_{whl_abi}"
            whl_name = f"kivy_sdl3-{version}-{tag}.whl"
            whl_path = self.p.wheelhouse / whl_name
            if whl_path.exists():
                log(f"  kivy-sdl3 {abi} wheel already exists, skipping.")
                continue

            tmp = self.p.wheelhouse / f"_kivy_sdl3_{whl_abi}_tmp"
            if tmp.exists():
                shutil.rmtree(tmp)
            pkg_dir = tmp / "kivy_sdl3"
            pkg_dir.mkdir(parents=True)

            # Copy all .so files for this ABI
            for lib in libs:
                lib_dir = android_output / lib / abi / "lib"
                if lib_dir.exists():
                    for so in lib_dir.glob("*.so"):
                        shutil.copy2(so, pkg_dir)

            # Minimal __init__.py
            (pkg_dir / "__init__.py").write_text("")

            # METADATA
            dist_info = tmp / f"kivy_sdl3-{version}.dist-info"
            dist_info.mkdir()
            meta = email.message.Message()
            meta["Metadata-Version"] = "2.1"
            meta["Name"] = "kivy-sdl3"
            meta["Version"] = version
            (dist_info / "METADATA").write_text(str(meta))
            (dist_info / "WHEEL").write_text(
                f"Wheel-Version: 1.0\nGenerator: build_kt\nRoot-Is-Purelib: false\nTag: {tag}\n"
            )
            (dist_info / "RECORD").write_text("")

            # Pack into wheel (zip)
            with zipfile.ZipFile(whl_path, "w", zipfile.ZIP_DEFLATED) as zf:
                for entry in tmp.rglob("*"):
                    if entry.is_file():
                        zf.write(entry, entry.relative_to(tmp))

            shutil.rmtree(tmp)
            log(f"  Created {whl_name}")


# ── ThorGPU ───────────────────────────────────────────────────────────────────

class ThorGPU(Builder):
    name = "thorgpu"
    wheel_prefix = "thorvg_cython-"

    THORVG_VERSION = "1.0.3"

    def build_macos(self) -> None:
        if self._has_wheel(Platform.MACOS):
            log("thorvg-cython macOS wheel already exists, skipping (delete it to rebuild).")
            return
        log("Building thorvg-cython macOS wheel (GPU/ANGLE)...")
        toolchain = xcode_toolchain_bin()

        tc = self.p.thorvg_cython_src
        before_all = (
            f"export PATH={toolchain}:$PATH && "
            f"python3 {tc}/tools/build_thorvg.py macos "
            f"--thorvg-root={tc}/thorvg "
            f"--version={self.THORVG_VERSION} --gpu=angle"
        )
        before_build = (
            "install_name_tool -id @rpath/libthorvg-1.dylib "
            f"{tc}/thorvg/output/macos_fat/libthorvg-1.dylib"
        )
        repair = (
            "delocate-wheel --require-archs {delocate_archs} "
            "-w {dest_dir} -v {wheel} && "
            f"python3 {THIS_FILE} _repair-thorgpu-wheel {{dest_dir}}"
        )
        cibw_env = " ".join([
            "THORVG_GPU=angle",
            f"THORVG_VERSION={self.THORVG_VERSION}",
            "THORVG_ROOT=thorvg",
            "THORVG_LIB_DIR=thorvg/output/macos_fat",
            f"ANGLE_LIB_DIR={self.p.angle_lib_dir}",
            "MACOSX_DEPLOYMENT_TARGET=11.0",
            f"PATH={toolchain}:$PATH",
        ])
        _cibuildwheel(self.p.thorvg_cython_src, Platform.MACOS, self.p, env={
            "THORVG_GPU": "angle",
            "CIBW_BEFORE_ALL_MACOS": before_all,
            "CIBW_BEFORE_BUILD_MACOS": before_build,
            "CIBW_REPAIR_WHEEL_COMMAND_MACOS": repair,
            "CIBW_TEST_COMMAND": "",
            "CIBW_ENVIRONMENT_MACOS": cibw_env,
        })
        log("thorvg-cython macOS done.")

    def build_ios(self) -> None:
        if self._has_wheel(Platform.IOS):
            log("thorvg-cython iOS wheels already exist, skipping (delete them to rebuild).")
            return
        log("Building thorvg-cython iOS wheels...")
        tc = self.p.thorvg_cython_src
        before_all = (
            f"python3 {tc}/tools/build_thorvg.py ios "
            f"--thorvg-root={tc}/thorvg "
            f"--version={self.THORVG_VERSION}"
        )
        _cibuildwheel(self.p.thorvg_cython_src, Platform.IOS, self.p, archs=IOS_ARCHS, env={
            "THORVG_GPU": "angle",
            "CIBW_BEFORE_ALL_IOS": before_all,
        })

        log("Injecting xcframeworks into thorvg-cython iOS wheels...")
        tvg_output = self.p.thorvg_cython_src / "thorvg" / "output"
        xcfw_args = [
            "--xcframework", tvg_output / "thorvg.xcframework",
            "--xcframework", tvg_output / "libomp.xcframework",
        ]
        for whl in sorted(self.p.wheelhouse.glob("thorvg_cython-*ios*.whl")):
            with tempfile.TemporaryDirectory() as tmpdir:
                run([
                    "python3", self.p.thorvg_cython_src / "tools" / "add-ios-frameworks.py",
                    str(whl), tmpdir,
                    *xcfw_args,
                ])
                patched = next(Path(tmpdir).glob("*.whl"))
                shutil.move(str(patched), str(whl))
        log("thorvg-cython iOS done.")

    def build_android(self) -> None:
        if self._has_wheel(Platform.ANDROID):
            log("thorvg-cython Android wheels already exist, skipping (delete them to rebuild).")
            return
        log("Building thorvg-cython Android wheels...")
        tc = self.p.thorvg_cython_src
        before_all = (
            f"python3 {tc}/tools/build_thorvg.py android "
            f"--thorvg-root={tc}/thorvg "
            f"--version={self.THORVG_VERSION}"
        )
        _cibuildwheel(self.p.thorvg_cython_src, Platform.ANDROID, self.p, archs=ANDROID_ARCHS, env={
            "ANDROID_NDK_HOME": str(self.p.android_ndk),
            "CIBW_BEFORE_ALL_ANDROID": before_all,
            "CIBW_TEST_COMMAND": "",
        })
        log("thorvg-cython Android done.")

    @staticmethod
    def repair_wheel(dest_dir: str) -> None:
        """Remove duplicate libthorvg-1.1.dylib from the repaired wheel."""
        import zipfile
        whl_name = next(p for p in os.listdir(dest_dir) if p.endswith(".whl"))
        src = os.path.join(dest_dir, whl_name)
        tmp = src + ".tmp"
        with zipfile.ZipFile(src, "r") as zin, zipfile.ZipFile(tmp, "w") as zout:
            for item in zin.infolist():
                if "libthorvg-1.1.dylib" in item.filename:
                    print(f"  Removing {item.filename}")
                    continue
                zout.writestr(item, zin.read(item.filename))
        os.replace(tmp, src)


# ── KivyThor ─────────────────────────────────────────────────────────────────

class KivyThor(Builder):
    name = "kivythor"
    wheel_prefix = "kivy_thor-"

    def build_macos(self) -> None:
        log("Building kivy-thor macOS wheel...")
        cibw_env = " ".join([
            "MACOSX_DEPLOYMENT_TARGET=11.0",
            f"PIP_FIND_LINKS={self.p.wheelhouse}",
            f"THORVG_CAPI_INCLUDE={self.p.thorvg_capi_include}",
            f"ANGLE_LIB_DIR={self.p.angle_lib_dir}",
            f"ANGLE_INCLUDE_DIR={self.p.angle_include_dir}",
        ])
        repair = (
            f"DYLD_LIBRARY_PATH={self.p.angle_lib_dir} "
            "delocate-listdeps {wheel} && "
            f"DYLD_LIBRARY_PATH={self.p.angle_lib_dir} "
            "delocate-wheel --require-archs {delocate_archs} "
            "--exclude libEGL --exclude libGLESv2 "
            "-w {dest_dir} {wheel} && "
            "for f in {dest_dir}/*.whl; do "
            f"python {self.p.kivy_thor_src}/scripts/build_kt.py _fix-egl-rpath \"$f\"; done"
        )
        _cibuildwheel(self.p.kivy_thor_src, Platform.MACOS, self.p, env={
            "PIP_FIND_LINKS": str(self.p.wheelhouse),
            "CIBW_ENVIRONMENT_MACOS": cibw_env,
            "CIBW_REPAIR_WHEEL_COMMAND_MACOS": repair,
        })
        log("kivy-thor macOS done.")

    def build_ios(self) -> None:
        log("Building kivy-thor iOS wheels...")
        # On iOS, EGL is resolved at app-link time via xcframework — do not
        # set ANGLE_LIB_DIR so setup.py doesn't link the macOS libEGL.dylib.
        # Use the iOS kivy-deps include dir for ANGLE headers.
        ios_angle_inc = self.p.ios_kivy_deps / "dist" / "include"
        cibw_env = " ".join([
            f"PIP_FIND_LINKS={self.p.wheelhouse}",
            f"THORVG_CAPI_INCLUDE={self.p.thorvg_capi_include}",
            f"ANGLE_INCLUDE_DIR={ios_angle_inc}",
            f"THORVG_CYTHON_SRC={self.p.thorvg_cython_src}",
        ])
        _cibuildwheel(self.p.kivy_thor_src, Platform.IOS, self.p, archs=IOS_ARCHS, env={
            "PIP_FIND_LINKS": str(self.p.wheelhouse),
            "CIBW_ENVIRONMENT_IOS": cibw_env,
        })
        log("kivy-thor iOS done.")

    def build_android(self) -> None:
        log("Building kivy-thor Android wheels...")
        cibw_env = " ".join([
            "ANDROID_API_LEVEL=21",
            f"PIP_FIND_LINKS={self.p.wheelhouse}",
            f"THORVG_CAPI_INCLUDE={self.p.thorvg_capi_include}",
            f"THORVG_CYTHON_SRC={self.p.thorvg_cython_src}",
        ])
        _cibuildwheel(self.p.kivy_thor_src, Platform.ANDROID, self.p, archs=ANDROID_ARCHS, env={
            "ANDROID_NDK_HOME": str(self.p.android_ndk),
            "PIP_FIND_LINKS": str(self.p.wheelhouse),
            "CIBW_ENVIRONMENT_ANDROID": cibw_env,
            "CIBW_REPAIR_WHEEL_COMMAND_ANDROID": "cp {wheel} {dest_dir}/",
        })
        log("kivy-thor Android done.")


# ── PyJnius ───────────────────────────────────────────────────────────────────

class PyJnius(Builder):
    """pyjnius Android wheel — Java/JNI bridge required by Kivy on Android."""
    name = "pyjnius"
    wheel_prefix = "pyjnius-"

    def build_macos(self) -> None:
        log("pyjnius: Android only — skipping macOS.")

    def build_ios(self) -> None:
        log("pyjnius: Android only — skipping iOS.")

    def build_android(self) -> None:
        if self._has_wheel(Platform.ANDROID):
            log("pyjnius Android wheels already exist, skipping (delete them to rebuild).")
            return
        log("Building pyjnius Android wheels...")
        _clone_if_missing(self.p.pyjnius_src, REPOS["pyjnius"])

        patch_script = THIS_FILE.parent / "patch_pyjnius.py"
        run([sys.executable, str(patch_script), str(self.p.pyjnius_src)])

        cibw_env = " ".join([
            "NDKPLATFORM=android",   # pyjnius uses these two to detect Android
            "LIBLINK=ld",
            f"PIP_FIND_LINKS={self.p.wheelhouse}",
        ])
        env: dict[str, str] = {
            "ANDROID_NDK_HOME": str(self.p.android_ndk),
            "CIBW_TEST_COMMAND": "",
            "CIBW_REPAIR_WHEEL_COMMAND_ANDROID": "cp {wheel} {dest_dir}/",
            "CIBW_BEFORE_BUILD_ANDROID": "pip install cython",
            "CIBW_ENVIRONMENT_ANDROID": cibw_env,
        }
        if java_home := os.environ.get("JAVA_HOME"):
            env["JAVA_HOME"] = java_home
        _cibuildwheel(self.p.pyjnius_src, Platform.ANDROID, self.p, archs=ANDROID_ARCHS, env=env)
        log("pyjnius Android done.")


class Pymunk(Builder):
    name = "pymunk"
    wheel_prefix = "pymunk-"

    def build_macos(self) -> None:
        log("pymunk: official wheels on PyPI — skipping macOS.")

    def build_ios(self) -> None:
        log("pymunk: official iOS wheels on PyPI — skipping.")

    def build_android(self) -> None:
        if self._has_wheel(Platform.ANDROID):
            log("pymunk Android wheels already exist, skipping (delete them to rebuild).")
            return
        log("Building pymunk Android wheels...")
        _clone_if_missing(self.p.pymunk_src, REPOS["pymunk"])
        # Munk2D is a git submodule — present in PyPI sdist but not in a bare clone
        if not (self.p.pymunk_src / "Munk2D" / "src").exists():
            # .gitmodules uses SSH; rewrite to HTTPS so no SSH key is needed
            run(["git", "config", "--file", ".gitmodules",
                 "submodule.Munk2D.url",
                 "https://github.com/viblo/Munk2D.git"],
                cwd=self.p.pymunk_src)
            run(["git", "submodule", "sync"], cwd=self.p.pymunk_src)
            run(["git", "submodule", "update", "--init", "--recursive"],
                cwd=self.p.pymunk_src)
        env: dict[str, str] = {
            "ANDROID_NDK_HOME": str(self.p.android_ndk),
            "CIBW_TEST_COMMAND": "",
            "CIBW_REPAIR_WHEEL_COMMAND_ANDROID": "cp {wheel} {dest_dir}/",
            "CIBW_BEFORE_BUILD_ANDROID": f"pip install cffi --no-index --find-links {self.p.wheelhouse}",
            "CIBW_ENVIRONMENT_ANDROID": " ".join([
                'LDFLAGS="-llog -lm"',
                f"PIP_FIND_LINKS={self.p.wheelhouse}",
            ]),
        }
        _cibuildwheel(self.p.pymunk_src, Platform.ANDROID, self.p, archs=ANDROID_ARCHS, env=env)
        log("pymunk Android done.")


class Cffi(Builder):
    name = "cffi"
    wheel_prefix = "cffi-"
    VERSION = "2.0.0"

    def build_macos(self) -> None:
        log("cffi: official wheels on PyPI — skipping macOS.")

    def build_ios(self) -> None:
        log("cffi: official wheels on PyPI — skipping iOS.")

    def build_android(self) -> None:
        if self._has_wheel(Platform.ANDROID):
            log("cffi Android wheels already exist, skipping (delete them to rebuild).")
            return
        log("Building cffi Android wheels...")
        src = self.p.cffi_src
        if not src.exists():
            import tarfile, urllib.request
            log(f"Downloading cffi {self.VERSION} sdist...")
            sdist_url = (
                f"https://files.pythonhosted.org/packages/source/c/cffi/"
                f"cffi-{self.VERSION}.tar.gz"
            )
            sdist_path = src.parent / f"cffi-{self.VERSION}.tar.gz"
            urllib.request.urlretrieve(sdist_url, sdist_path)
            with tarfile.open(sdist_path) as tf:
                tf.extractall(src.parent)
            (src.parent / f"cffi-{self.VERSION}").rename(src)

        # Apply patches to cffi/setup.py on the host before invoking cibuildwheel.
        # patch_cffi.py is idempotent; safe to run every time.
        patch_cffi = THIS_FILE.parent / "patch_cffi.py"
        run([sys.executable, str(patch_cffi), str(src)])

        fetch_ffi = THIS_FILE.parent / "fetch_ffi_headers.py"
        env: dict[str, str] = {
            "ANDROID_NDK_HOME": str(self.p.android_ndk),
            "CIBW_TEST_COMMAND": "",
            "CIBW_REPAIR_WHEEL_COMMAND_ANDROID": "cp {wheel} {dest_dir}/",
            # Download BeeWare's pre-built libffi for both Android archs.
            # The patched setup.py reads $CC to pick the right arch dir.
            "CIBW_BEFORE_ALL_ANDROID": f"python3 {fetch_ffi}",
        }
        _cibuildwheel(src, Platform.ANDROID, self.p, archs=ANDROID_ARCHS, env=env)
        log("cffi Android done.")


# ── Registry & build order ────────────────────────────────────────────────────

BUILDERS: dict[str, type[Builder]] = {
    "pyjnius":  PyJnius,
    "cffi":     Cffi,
    "pymunk":   Pymunk,
    "kivy":     Kivy,
    "thorgpu":  ThorGPU,
    "kivythor": KivyThor,
}

BUILD_ORDER = ["pyjnius", "cffi", "pymunk", "kivy", "thorgpu", "kivythor"]


# ── CLI ───────────────────────────────────────────────────────────────────────

REPOS = {
    "kivy":          "https://github.com/kivy/kivy",
    "thorvg-cython": "https://github.com/psychowasp/thorvg-cython.git",
    "pyjnius":       "https://github.com/kivy/pyjnius.git",
    "pymunk":        "https://github.com/viblo/pymunk.git",
}


def _clone_if_missing(dest: Path, url: str) -> None:
    if not dest.exists():
        log(f"Cloning {url} into {dest}")
        subprocess.run(["git", "clone", url, str(dest)], check=True)
        # Make shell scripts executable (git may lose +x on some platforms)
        for sh in dest.rglob("*.sh"):
            sh.chmod(sh.stat().st_mode | 0o111)


def _discover_paths() -> Paths:
    """Auto-discover all paths from CWD, with env var overrides.

    Clones kivy and thorvg-cython if they don't exist yet.
    """
    root = Path.cwd()

    def p(env_key: str, default: Path) -> Path:
        val = os.environ.get(env_key)
        return Path(val).resolve() if val else default

    kivy_src     = p("KIVY_SRC",          root / "kivy")
    tc_src       = p("THORVG_CYTHON_SRC", root / "thorvg-cython")
    kt_src       = p("KIVY_THOR_SRC",     root / "kivy-thor")
    pyjnius_src  = p("PYJNIUS_SRC",       root / "pyjnius")
    pymunk_src   = p("PYMUNK_SRC",        root / "pymunk")
    cffi_src     = p("CFFI_SRC",          root / "cffi")

    _clone_if_missing(kivy_src,    REPOS["kivy"])
    _clone_if_missing(tc_src,      REPOS["thorvg-cython"])
    _clone_if_missing(pyjnius_src, REPOS["pyjnius"])
    _clone_if_missing(pymunk_src,  REPOS["pymunk"])

    kivy_deps = p("KIVY_DEPS_ROOT",      kivy_src / "kivy-dependencies")

    ndk_path = os.environ.get("ANDROID_NDK_HOME") or os.environ.get("ANDROID_NDK", "")
    android_ndk = Path(ndk_path) if ndk_path else None

    if android_ndk is not None and not android_ndk.is_dir():
        print(f"ERROR: ANDROID_NDK_HOME={android_ndk} does not exist", file=sys.stderr)
        sys.exit(1)

    return Paths(
        wheelhouse          = p("WHEELHOUSE",          root / "wheelhouse"),
        kivy_src            = kivy_src,
        thorvg_cython_src   = tc_src,
        kivy_thor_src       = kt_src,
        pyjnius_src         = pyjnius_src,
        pymunk_src          = pymunk_src,
        cffi_src            = cffi_src,
        kivy_deps           = kivy_deps,
        ios_kivy_deps       = p("IOS_KIVY_DEPS_ROOT",  kivy_src / "ios-kivy-dependencies"),
        angle_lib_dir       = p("ANGLE_LIB_DIR",       kivy_deps / "dist" / "lib"),
        angle_include_dir   = p("ANGLE_INCLUDE_DIR",   kivy_deps / "dist" / "include"),
        thorvg_capi_include = p("THORVG_CAPI_INCLUDE", tc_src / "thorvg" / "src" / "bindings" / "capi"),
        android_ndk         = android_ndk or Path(""),
    )


def _fix_egl_rpath(whl_path: str) -> None:
    """Rewrite @rpath/libEGL.dylib references in a wheel to use @loader_path.

    After delocate excludes libEGL/libGLESv2, the .so files still reference
    them via @rpath which won't resolve at runtime.  We change the install
    name to @loader_path/../kivy/.dylibs/libEGL.dylib so it resolves
    relative to the installed .so in site-packages.
    """
    import glob, subprocess, tempfile, zipfile, shutil
    tmp = tempfile.mkdtemp()
    try:
        with zipfile.ZipFile(whl_path, "r") as zf:
            zf.extractall(tmp)
        changed = False
        for so in glob.glob(os.path.join(tmp, "kivy_thor", "*.so")):
            otool = subprocess.run(["otool", "-L", so], capture_output=True, text=True)
            if "@rpath/libEGL.dylib" in otool.stdout:
                subprocess.run([
                    "install_name_tool", "-change",
                    "@rpath/libEGL.dylib",
                    "@loader_path/../kivy/.dylibs/libEGL.dylib",
                    so,
                ], check=True)
                changed = True
                log(f"  Fixed EGL rpath in {os.path.basename(so)}")
        if changed:
            os.remove(whl_path)
            with zipfile.ZipFile(whl_path, "w", zipfile.ZIP_DEFLATED) as zf:
                for root, _dirs, files in os.walk(tmp):
                    for f in files:
                        full = os.path.join(root, f)
                        zf.write(full, os.path.relpath(full, tmp))
            log(f"  Repacked {os.path.basename(whl_path)}")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main() -> None:
    # Hidden callback used by cibuildwheel's CIBW_REPAIR_WHEEL_COMMAND
    if len(sys.argv) >= 2 and sys.argv[1] == "_repair-thorgpu-wheel":
        ThorGPU.repair_wheel(sys.argv[2])
        return

    if len(sys.argv) >= 3 and sys.argv[1] == "_fix-egl-rpath":
        _fix_egl_rpath(sys.argv[2])
        return

    parser = argparse.ArgumentParser(
        description="Build wheels for the Kivy-Thor stack.",
    )
    parser.add_argument(
        "builder",
        choices=[*BUILDERS, "all"],
        help="Which package to build (or 'all' for the full chain).",
    )
    parser.add_argument(
        "platform",
        choices=["macos", "ios", "android", "all"],
        help="Target platform (or 'all' for macOS + iOS + Android).",
    )
    args = parser.parse_args()

    paths = _discover_paths()
    paths.wheelhouse.mkdir(parents=True, exist_ok=True)

    names = BUILD_ORDER if args.builder == "all" else [args.builder]
    platforms = (
        [Platform.MACOS, Platform.IOS, Platform.ANDROID]
        if args.platform == "all"
        else [Platform(args.platform)]
    )
    builders = [BUILDERS[n](paths) for n in names]

    log(f"Wheelhouse: {paths.wheelhouse}")
    for builder in builders:
        for platform in platforms:
            builder.build(platform)

    log("All requested builds complete.")


if __name__ == "__main__":
    main()
