from wheelbuilder.platforminfo import SDK
from wheelbuilder.protocols import CiWheelBase


class Pynacl(CiWheelBase):
    def env(self):
        env = self.base_env()
        if self.platform.sdk == SDK.android:
            # LDSHARED override: Android Python's sysconfigdata embeds a
            # hardcoded builder-machine path (e.g. /Users/msmith/...) with
            # the wrong API level. $CC in CIBW_ENVIRONMENT is not expanded
            # (CC isn't set at env-evaluation time). Use a wrapper script
            # created in BEFORE_BUILD that defers $CC expansion to link time.
            env["CIBW_ENVIRONMENT_ANDROID"] = 'SODIUM_INSTALL="bundled" PKG_CONFIG_PATH="" MAKE=/tmp/pynacl_make_wrapper LDSHARED=/tmp/pynacl_ldshared'
            # Wrap libsodium's configure to add --host at runtime (reading CC since
            # CIBW_HOST_TRIPLET is not available in before_build env, only android_env).
            # Wrap make so that "make check" is skipped for Android cross-compilation.
            env["CIBW_BEFORE_BUILD_ANDROID"] = """\
SRC="{package}/src/libsodium"
if [ ! -f "$SRC/configure.orig" ]; then
    mv "$SRC/configure" "$SRC/configure.orig"
fi
cat > "$SRC/configure" << 'CONFSCRIPT'
#!/bin/sh
SDIR=$(cd "$(dirname "$0")" && pwd)
CC_BASE=$(basename "${CC:-}")
HOST=$(echo "$CC_BASE" | sed 's/[0-9]*-clang$//')
if echo "$HOST" | grep -q 'linux-android'; then
    exec "$SDIR/configure.orig" --host="$HOST" "$@"
else
    exec "$SDIR/configure.orig" "$@"
fi
CONFSCRIPT
chmod +x "$SRC/configure"
cat > /tmp/pynacl_make_wrapper << 'MAKESCRIPT'
#!/bin/sh
if [ "$1" = "check" ] && echo "${CC:-}" | grep -q 'linux-android'; then
    echo "Skipping make check for Android cross-compilation"
    exit 0
fi
unset MAKE
exec make "$@"
MAKESCRIPT
chmod +x /tmp/pynacl_make_wrapper
cat > /tmp/pynacl_ldshared << 'LDSCRIPT'
#!/bin/sh
exec ${CC} -shared "$@"
LDSCRIPT
chmod +x /tmp/pynacl_ldshared"""
        else:
            # iOS: with default build isolation pip installs cffi iOS binary into
            # the isolated venv, but macOS Python can't import the iOS-targeted
            # _cffi_backend extension. Use --no-build-isolation so we control the
            # build env, then replace the iOS cffi with a macOS build using zipfile
            # extraction (pip install rejects macOS wheels in the iOS-targeted venv).
            # Also patch setup.py so libsodium configure gets --host (cross-compile
            # mode) and make check is skipped (can't run iOS binaries on macOS).
            # {package} expands to the absolute path of the pynacl source dir.
            env["CIBW_BUILD_FRONTEND"] = "build; args: --no-isolation"
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
    if (n.startswith('cffi/') or '_cffi_backend' in n or (n.startswith('cffi-') and '.dist-info/' in n)) and not n.endswith('/'):
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
