from wheelbuilder.platforminfo import SDK
from wheelbuilder.protocols import CiWheelBase


class Pynacl(CiWheelBase):
    def env(self):
        env = self.base_env()
        if self.platform.sdk == SDK.android:
            env["CIBW_ENVIRONMENT_ANDROID"] = 'SODIUM_INSTALL="bundled" PKG_CONFIG_PATH=""'
            # {package} expands to the absolute path of the pynacl source dir.
            # CIBW_HOST_TRIPLET is set by cibuildwheel before BEFORE_BUILD runs
            # (e.g. "aarch64-linux-android"). Passing --host and
            # --enable-android-cross-compilation to libsodium configure prevents
            # it from exiting 77 (AC_MSG_FAILURE) on cross-compile AC_TRY_RUN tests.
            env["CIBW_BEFORE_BUILD_ANDROID"] = """\
python3 - "{package}" << 'PYEOF'
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
            # _cffi_backend extension. Use --no-build-isolation so we control the
            # build env, then replace the iOS cffi with a macOS build using zipfile
            # extraction (pip install rejects macOS wheels in the iOS-targeted venv).
            # Also patch setup.py so libsodium configure gets --host (cross-compile
            # mode) and make check is skipped (can't run iOS binaries on macOS).
            # {package} expands to the absolute path of the pynacl source dir.
            env["CIBW_BUILD_FRONTEND_IOS"] = "pip; args: --no-build-isolation"
            env["CIBW_BEFORE_BUILD_IOS"] = """\
python3 -m pip download --only-binary :all: --platform macosx_11_0_arm64 --python-version "$(python3 -c 'import sys; v=sys.version_info; print(str(v[0])+"."+str(v[1]))')" --implementation cp cffi -d /tmp/pynacl_cffi_dl --quiet
python3 - << 'CFFIEOF'
import zipfile, pathlib, site, shutil
sd = pathlib.Path(site.getsitepackages()[0])
whl = list(pathlib.Path('/tmp/pynacl_cffi_dl').glob('cffi*.whl'))[0]
for p in list(sd.glob('cffi*')) + list(sd.glob('_cffi_backend*')):
    shutil.rmtree(p) if p.is_dir() else p.unlink(missing_ok=True)
z = zipfile.ZipFile(whl)
for n in z.namelist():
    if (n.startswith('cffi/') or '_cffi_backend' in n) and not n.endswith('/'):
        t = sd / n
        t.parent.mkdir(parents=True, exist_ok=True)
        t.write_bytes(z.read(n))
CFFIEOF
pip install setuptools wheel
python3 - "{package}" << 'PYEOF'
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
