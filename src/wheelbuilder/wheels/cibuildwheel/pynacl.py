from wheelbuilder.platforminfo import SDK
from wheelbuilder.protocols import CiWheelBase

_SODIUM_PREFIX = "/tmp/pynacl_sodium"
_PYPI_INDEX = "https://pypi-index.psychowaspx.workers.dev/simple/"


class Pynacl(CiWheelBase):
    def env(self):
        env = self.base_env()

        # Build libsodium ourselves (skip 'make check') so we can use
        # SODIUM_INSTALL=system and avoid pynacl's bundled build entirely.
        # libsodium.sh uses sysconfig.get_platform() to infer --host and,
        # for Android, sets CC to the NDK clang explicitly (CC is not the
        # NDK clang at BEFORE_BUILD time, only during the actual build step).
        build_sodium = (
            f"bash ${{GITHUB_WORKSPACE}}/src/wheelbuilder/scripts/libsodium.sh"
            f' "{{package}}/src/libsodium" "{_SODIUM_PREFIX}"'
        )

        sodium_env = [
            'SODIUM_INSTALL="system"',
            'PYNACL_SODIUM_STATIC="1"',
            f'CFLAGS="$CFLAGS -I{_SODIUM_PREFIX}/include"',
            f'LDFLAGS="$LDFLAGS -L{_SODIUM_PREFIX}/lib"',
            f'PIP_EXTRA_INDEX_URL="{_PYPI_INDEX}"',
        ]

        if self.platform.sdk == SDK.android:
            # Android's _sysconfigdata_*.py has a hardcoded builder-machine path
            # for LDSHARED; $CC is not set at CIBW_ENVIRONMENT evaluation time,
            # so we create the wrapper in BEFORE_BUILD and reference it by path.
            sodium_env.append('LDSHARED="/tmp/pynacl_ldshared"')
            env["CIBW_ENVIRONMENT_ANDROID"] = " ".join(sodium_env)
            env["CIBW_BEFORE_BUILD_ANDROID"] = (
                "cat > /tmp/pynacl_ldshared << 'EOF'\n"
                "#!/bin/sh\n"
                "exec ${CC} -shared \"$@\"\n"
                "EOF\n"
                "chmod +x /tmp/pynacl_ldshared\n"
                + build_sodium
            )
        else:
            env["CIBW_ENVIRONMENT_IOS"] = " ".join(sodium_env)
            env["CIBW_BEFORE_BUILD_IOS"] = build_sodium

        return env
