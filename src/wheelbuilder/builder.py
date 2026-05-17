from __future__ import annotations

import json
import urllib.error
import urllib.request
from enum import Enum
from pathlib import Path

from wheelbuilder import tools
from wheelbuilder.platforms import (
    Android_arm64,
    Android_x86_64,
    Iphoneos,
    IphoneSimulator_arm64,
    IphoneSimulator_x86_64,
    PlatformBase,
)
from wheelbuilder.protocols import CiWheelBase, LibraryWheelBase, WheelBase


class BuildPlatform(str, Enum):
    ios = "ios"
    android = "android"

    def __str__(self) -> str:
        return self.value


def resolve_platforms(
    filter_: BuildPlatform | None, wheel_cls: type[WheelBase] | None
) -> list[PlatformBase]:
    if filter_ == BuildPlatform.ios:
        return [Iphoneos(), IphoneSimulator_arm64(), IphoneSimulator_x86_64()]
    if filter_ == BuildPlatform.android:
        return [Android_arm64(), Android_x86_64()]
    if wheel_cls is not None:
        return wheel_cls.supported_platforms()
    return [
        Iphoneos(),
        IphoneSimulator_arm64(),
        IphoneSimulator_x86_64(),
        Android_arm64(),
        Android_x86_64(),
    ]


def build_wheels(
    wheel_cls: type[WheelBase],
    version: str | None,
    platform_filter: BuildPlatform | None,
    wheel_output: Path,
) -> None:
    with tools.with_temp() as working_dir:
        platforms = resolve_platforms(platform_filter, wheel_cls)
        for platform in platforms:
            wheel = wheel_cls.new(version=version, platform=platform, root=working_dir)

            # Library-only wheels: build the library, no cibuildwheel step.
            if isinstance(wheel, LibraryWheelBase) and not isinstance(wheel, CiWheelBase):
                wheel.pre_build_library(working_dir)
                wheel.build_library_platform(working_dir)
                wheel.post_build_library(working_dir)
                continue

            for lib_cls in wheel.dependencies_libraries():
                lib = lib_cls.new(version=None, platform=platform, root=working_dir)
                lib.pre_build_library(working_dir)
                lib.build_library_platform(working_dir)
                lib.post_build_library(working_dir)

            if isinstance(wheel, CiWheelBase):
                wheel.build_wheel(working_dir, version, wheel_output)


def compare_versions(name: str) -> list[BuildPlatform]:
    """Return platforms whose latest anaconda upload lags pypi.

    Mirrors Swift `compare_versions`. If pypi or anaconda lookup fails the
    function returns all build platforms (safe default).
    """
    pypi_version = _fetch_pypi_version(name)
    if pypi_version is None:
        return list(BuildPlatform)
    files = _fetch_anaconda_files(name)
    if files is None:
        return list(BuildPlatform)
    ios_versions = [f["version"] for f in files if _is_ios(f.get("basename", ""))]
    android_versions = [f["version"] for f in files if "android" in f.get("basename", "")]
    ios_latest = max(ios_versions) if ios_versions else None
    android_latest = max(android_versions) if android_versions else None
    needed: list[BuildPlatform] = []
    if ios_latest is None or pypi_version > ios_latest:
        needed.append(BuildPlatform.ios)
    if android_latest is None or pypi_version > android_latest:
        needed.append(BuildPlatform.android)
    if needed:
        print(f"\n############# {name} #############")
        print(f"pypi version:    {pypi_version}")
        print(f"ios latest:      {ios_latest or 'missing'}")
        print(f"android latest:  {android_latest or 'missing'}")
        print(f"needs build:     {', '.join(p.value for p in needed)}")
        print("##########################################\n")
    return needed


def _is_ios(basename: str) -> bool:
    return "iphoneos" in basename or "iphonesimulator" in basename


def _fetch_pypi_version(name: str) -> str | None:
    try:
        with urllib.request.urlopen(f"https://pypi.org/pypi/{name}/json") as resp:
            data = json.load(resp)
    except (urllib.error.URLError, json.JSONDecodeError):
        return None
    info = data.get("info") or {}
    version = info.get("version")
    return version if isinstance(version, str) else None


def _fetch_anaconda_files(name: str) -> list[dict] | None:
    try:
        with urllib.request.urlopen(f"https://api.anaconda.org/package/pyswift/{name}") as resp:
            data = json.load(resp)
    except (urllib.error.URLError, json.JSONDecodeError):
        return None
    files = data.get("files")
    return files if isinstance(files, list) else None
