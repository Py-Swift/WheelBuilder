from wheelbuilder.platforminfo import SDK
from wheelbuilder.protocols import CiWheelBase


class Pynacl(CiWheelBase):
    def env(self):
        env = self.base_env()
        if self.platform.sdk == SDK.android:
            env["CIBW_ENVIRONMENT_ANDROID"] = 'SODIUM_INSTALL="bundled" PKG_CONFIG_PATH=""'
            # libsodium configure exits 77 (AC_MSG_FAILURE) without --host because
            # autoconf can't determine cross-compile mode. Use {project} for an
            # absolute path to setup.py (CWD during BEFORE_BUILD is not guaranteed)
            # and read CIBW_HOST_TRIPLET which cibuildwheel exports before running
            # BEFORE_BUILD (e.g. "aarch64-linux-android").
            env["CIBW_BEFORE_BUILD_ANDROID"] = """\
python3 - "{project}" << 'PYEOF'
import sys, os
src = sys.argv[1]
host = os.environ.get('CIBW_HOST_TRIPLET', '')
if host and 'linux-android' in host:
    setup = os.path.join(src, 'setup.py')
    with open(setup) as f:
        t = f.read()
    t = t.replace(
        '"--with-pic",',
        '"--with-pic", "--host=' + host + '", "--enable-android-cross-compilation",',
    )
    with open(setup, 'w') as f:
        f.write(t)
PYEOF"""
        else:
            # iOS: with default build isolation pip installs cffi iOS binary into
            # the isolated venv, but macOS Python can't import the iOS-targeted
            # _cffi_backend extension (wrong suffix: .cpython-313-arm-apple-ios.so
            # vs .cpython-313-darwin.so). Use --no-build-isolation so we control
            # the build env, then reinstall the macOS cffi wheel via --force-reinstall
            # (cffi 2.0 may already be installed; extraction to existing dir errors).
            # Also patch setup.py so libsodium configure gets --host (cross-compile
            # mode) and make check is skipped (can't run iOS binaries on macOS).
            # Use {project} for absolute path to setup.py.
            env["CIBW_BUILD_FRONTEND_IOS"] = "pip; args: --no-build-isolation"
            env["CIBW_BEFORE_BUILD_IOS"] = """\
pip download --only-binary :all: --platform macosx_11_0_arm64 --python-version 3.13 --implementation cp cffi -d /tmp/pynacl_cffi_dl --quiet
python3 -c "import pathlib,subprocess,sys; whl=list(pathlib.Path('/tmp/pynacl_cffi_dl').glob('cffi*.whl'))[0]; subprocess.check_call([sys.executable,'-m','pip','install','--force-reinstall','--no-deps',str(whl)])"
pip install setuptools wheel
python3 - "{project}" << 'PYEOF'
import sys, os
cc = os.environ.get('CC', os.environ.get('CXX', '')).split('/')[-1]
host = 'x86_64-apple-darwin10' if 'x86_64' in cc else 'arm-apple-darwin10'
setup = os.path.join(sys.argv[1], 'setup.py')
with open(setup) as f:
    t = f.read()
t = t.replace('"--with-pic",', '"--with-pic", "--host=' + host + '",')
t = t.replace(
    'subprocess.check_call([make_command, "check"]',
    'if False: subprocess.check_call([make_command, "check"]',
)
with open(setup, 'w') as f:
    f.write(t)
PYEOF"""
            env["CIBW_ENVIRONMENT_IOS"] = 'SODIUM_INSTALL="bundled"'
        return env
