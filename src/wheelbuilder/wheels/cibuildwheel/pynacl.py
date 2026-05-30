from wheelbuilder.platforminfo import SDK
from wheelbuilder.protocols import CiWheelBase


class Pynacl(CiWheelBase):
    def env(self):
        env = self.base_env()
        if self.platform.sdk == SDK.android:
            env["CIBW_ENVIRONMENT_ANDROID"] = 'SODIUM_INSTALL="bundled" PKG_CONFIG_PATH=""'
            # libsodium's configure exits 77 without --host: autoconf can't detect
            # the cross-compile target. Extract arch from CC (e.g. aarch64-linux-
            # android24-clang) and pass --host=<arch>-linux-android plus
            # --enable-android-cross-compilation (which also disables make check).
            env["CIBW_BEFORE_BUILD_ANDROID"] = """\
python3 - << 'PYEOF'
import os
cc = os.environ.get('CC', '').split('/')[-1]
if '-linux-android' in cc:
    arch = cc.split('-')[0]
    host = arch + '-linux-android'
    with open('setup.py') as f:
        t = f.read()
    t = t.replace(
        '"--with-pic",',
        '"--with-pic", "--host=' + host + '", "--enable-android-cross-compilation",',
    )
    with open('setup.py', 'w') as f:
        f.write(t)
PYEOF"""
        else:
            # iOS: with default build isolation pip installs cffi iOS binary into
            # the isolated venv, but macOS Python can't import the iOS-targeted
            # _cffi_backend extension (wrong suffix: .cpython-313-arm-apple-ios.so
            # vs .cpython-313-darwin.so). Use --no-build-isolation so we control
            # the build env, then manually extract cffi macOS binary into
            # site-packages so _cffi_backend.cpython-313-darwin.so is importable.
            # Also patch setup.py so libsodium configure gets --host (cross-compile
            # mode) and make check is skipped (can't run iOS binaries on macOS).
            env["CIBW_BUILD_FRONTEND_IOS"] = "pip; args: --no-build-isolation"
            env["CIBW_BEFORE_BUILD_IOS"] = """\
pip download --only-binary :all: --platform macosx_11_0_arm64 --python-version 3.13 --implementation cp cffi -d /tmp/pynacl_cffi_dl --quiet
python3 -c "import zipfile,pathlib,site; sd=pathlib.Path(site.getsitepackages()[0]); whl=list(pathlib.Path('/tmp/pynacl_cffi_dl').glob('cffi*.whl'))[0]; z=zipfile.ZipFile(whl); [sd.joinpath(n).parent.mkdir(parents=True,exist_ok=True) or sd.joinpath(n).write_bytes(z.read(n)) for n in z.namelist() if n.startswith('cffi/') or '_cffi_backend' in n]"
pip install setuptools wheel
python3 - << 'PYEOF'
import os
cc = os.environ.get('CC', os.environ.get('CXX', '')).split('/')[-1]
host = 'x86_64-apple-darwin10' if 'x86_64' in cc else 'arm-apple-darwin10'
with open('setup.py') as f:
    t = f.read()
t = t.replace('"--with-pic",', '"--with-pic", "--host=' + host + '",')
t = t.replace(
    'subprocess.check_call([make_command, "check"]',
    'if False: subprocess.check_call([make_command, "check"]',
)
with open('setup.py', 'w') as f:
    f.write(t)
PYEOF"""
            env["CIBW_ENVIRONMENT_IOS"] = 'SODIUM_INSTALL="bundled"'
        return env
