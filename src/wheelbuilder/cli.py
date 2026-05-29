from __future__ import annotations

import argparse
import sys
from pathlib import Path

from wheelbuilder.builder import BuildPlatform, build_wheels, compare_versions
from wheelbuilder.piprepo import RepoFolder
from wheelbuilder.registry import WHEELS


class WheelBuilderCLI:
    def __init__(self) -> None:
        self.parser = self._make_parser()

    def _make_parser(self) -> argparse.ArgumentParser:
        parser = argparse.ArgumentParser(prog="wheelbuilder")
        sub = parser.add_subparsers(dest="command", required=True)

        build = sub.add_parser("build", help="Build a single anaconda package")
        build.add_argument("package")
        build.add_argument("output")
        build.add_argument("--version", default=None)
        build.add_argument(
            "--platform",
            choices=[p.value for p in BuildPlatform],
            default=None,
        )
        build.add_argument("--all", action="store_true")
        build.set_defaults(func=self.cmd_build)

        build_all = sub.add_parser("build-all", help="Build every supported package")
        build_all.add_argument("output")
        build_all.add_argument(
            "--platform",
            choices=[p.value for p in BuildPlatform],
            default=None,
        )
        build_all.set_defaults(func=self.cmd_build_all)

        action = sub.add_parser(
            "action-build",
            help="Build all packages, optionally only those needing updates",
        )
        action.add_argument("output")
        action.add_argument(
            "--checks",
            action="store_true",
            help="Only build packages whose pypi version is newer than anaconda",
        )
        action.set_defaults(func=self.cmd_action_build)

        repo = sub.add_parser("pip-repo", help="Generate a simple-index HTML repo")
        repo.add_argument("src_folder")
        repo.add_argument("output")
        repo.set_defaults(func=self.cmd_pip_repo)

        return parser

    # -------------------------------------------------------------- commands

    def cmd_build(self, args: argparse.Namespace) -> None:
        wheel_cls = WHEELS.get(args.package)
        if wheel_cls is None:
            raise SystemExit(f"unsupported package: {args.package}")
        platform = BuildPlatform(args.platform) if args.platform else None
        build_wheels(wheel_cls, args.version, platform, Path(args.output))

    def cmd_build_all(self, args: argparse.Namespace) -> None:
        platform = BuildPlatform(args.platform) if args.platform else None
        for wheel_cls in WHEELS.values():
            build_wheels(wheel_cls, None, platform, Path(args.output))

    def cmd_action_build(self, args: argparse.Namespace) -> None:
        output = Path(args.output)
        failed: list[str] = []
        for name, wheel_cls in WHEELS.items():
            try:
                if args.checks:
                    platforms = compare_versions(name)
                    if not platforms:
                        continue
                    filter_ = platforms[0] if len(platforms) == 1 else None
                    build_wheels(wheel_cls, None, filter_, output)
                else:
                    build_wheels(wheel_cls, None, None, output)
            except Exception as exc:
                print(f"[FAILED] {name}: {exc}")
                failed.append(name)
        if failed:
            raise SystemExit(f"Failed packages: {', '.join(failed)}")

    def cmd_pip_repo(self, args: argparse.Namespace) -> None:
        repo = RepoFolder(Path(args.src_folder))
        repo.generate_simple(Path(args.output))

    # ------------------------------------------------------------------ run

    def run(self, argv: list[str] | None = None) -> int:
        args = self.parser.parse_args(argv)
        args.func(args)
        return 0


def main(argv: list[str] | None = None) -> int:
    return WheelBuilderCLI().run(argv if argv is not None else sys.argv[1:])
