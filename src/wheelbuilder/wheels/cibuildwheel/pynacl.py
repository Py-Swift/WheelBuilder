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
            # iOS: pip installs the iOS-targeted cffi binary into the venv,
            # but macOS Python can't import it. Strategy: --no-build-isolation
            # to control the env, then replace iOS cffi with a macOS-compatible
            # binary via zipfile extraction (pip rejects cross-platform wheels).
            # pycparser is installed separately (cffi 1.15+ no longer bundles it).
            #
            # BEFORE_BUILD runs once per Python version per arch. Use a
            # Python-version-specific cffi download dir so cp313 and cp314
            # wheels don't conflict.
            #
            # Skip 'make check' (can't run iOS binaries on macOS) by prepending
            # /tmp/pynacl_ios_make to PATH with a make wrapper that exits 0 for
            # the check target.
            #
            # Add --host to libsodium configure via a wrapper script that reads
            # CC at configure time (CC is only set during the build step, not
            # during BEFORE_BUILD).
            env["CIBW_BUILD_FRONTEND"] = "pip; args: --no-build-isolation"
            env["CIBW_ENVIRONMENT_IOS"] = 'SODIUM_INSTALL="bundled" PATH="/tmp/pynacl_ios_make:$PATH"'
            env["CIBW_BEFORE_BUILD_IOS"] = """\
PY_VER=$(python3 -c 'import sys; v=sys.version_info; print(str(v[0])+"."+str(v[1]))')
CFFI_DIR="/tmp/pynacl_cffi_${PY_VER//./}"
mkdir -p "${CFFI_DIR}"
python3 -m pip download --only-binary :all: --platform macosx_11_0_arm64 --python-version "${PY_VER}" --implementation cp cffi -d "${CFFI_DIR}" --quiet
python3 - "${CFFI_DIR}" << 'CFFIEOF'
import zipfile, pathlib, site, shutil, sys
dl_dir = pathlib.Path(sys.argv[1])
sd = pathlib.Path(site.getsitepackages()[0])
whl = list(dl_dir.glob('cffi*.whl'))[0]
for p in list(sd.glob('cffi*')) + list(sd.glob('_cffi_backend*')):
    shutil.rmtree(p) if p.is_dir() else p.unlink(missing_ok=True)
z = zipfile.ZipFile(whl)
for n in z.namelist():
    if (n.startswith('cffi/') or '_cffi_backend' in n or (n.startswith('cffi-') and '.dist-info/' in n)) and not n.endswith('/'):
        t = sd / n
        t.parent.mkdir(parents=True, exist_ok=True)
        t.write_bytes(z.read(n))
CFFIEOF
pip install setuptools wheel pycparser
mkdir -p /tmp/pynacl_ios_make
cat > /tmp/pynacl_ios_make/make << 'MAKE_WRAPPER'
#!/bin/sh
if [ "$1" = "check" ]; then
    echo "Skipping make check for iOS cross-compilation"
    exit 0
fi
exec /usr/bin/make "$@"
MAKE_WRAPPER
chmod +x /tmp/pynacl_ios_make/make
SRC="{package}/src/libsodium"
if [ ! -f "$SRC/configure.orig" ]; then
    mv "$SRC/configure" "$SRC/configure.orig"
fi
cat > "$SRC/configure" << 'CONFSCRIPT'
#!/bin/sh
SDIR=$(cd "$(dirname "$0")" && pwd)
CC_BASE=$(basename "${CC:-}")
HOST=""
if echo "$CC_BASE" | grep -q 'x86_64.*ios'; then
    HOST="x86_64-apple-ios-simulator"
elif echo "$CC_BASE" | grep -q 'simulator'; then
    HOST="aarch64-apple-ios-simulator"
elif echo "$CC_BASE" | grep -q 'arm64'; then
    HOST="aarch64-apple-ios"
fi
if [ -n "$HOST" ]; then
    exec "$SDIR/configure.orig" --host="$HOST" "$@"
else
    exec "$SDIR/configure.orig" "$@"
fi
CONFSCRIPT
chmod +x "$SRC/configure\""""
        return env
