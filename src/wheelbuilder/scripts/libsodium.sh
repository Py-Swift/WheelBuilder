#!/bin/bash
# Cross-compile libsodium from source (skips 'make check').
# Usage: libsodium.sh <src_dir> <install_prefix>
# Detects target platform via Python sysconfig (reliable in cibuildwheel BEFORE_BUILD).
set -euo pipefail

SRC_DIR="$1"
PREFIX="$2"

PLAT=$(python3 -c "import sysconfig; print(sysconfig.get_platform())" 2>/dev/null || echo "")
echo "=== libsodium.sh: PLAT='$PLAT' CC='${CC:-}' NDK='${ANDROID_NDK_HOME:-}' ==="

HOST=""

case "$PLAT" in
    android-*-arm64|android-*-aarch64)
        HOST="aarch64-linux-android"
        API="${ANDROID_API_LEVEL:-24}"
        NDK="${ANDROID_NDK_HOME:?ANDROID_NDK_HOME must be set}"
        NDK_TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin"
        export CC="$NDK_TOOLCHAIN/aarch64-linux-android${API}-clang"
        export CXX="$NDK_TOOLCHAIN/aarch64-linux-android${API}-clang++"
        export AR="$NDK_TOOLCHAIN/llvm-ar"
        export RANLIB="$NDK_TOOLCHAIN/llvm-ranlib"
        ;;
    android-*-x86_64)
        HOST="x86_64-linux-android"
        API="${ANDROID_API_LEVEL:-24}"
        NDK="${ANDROID_NDK_HOME:?ANDROID_NDK_HOME must be set}"
        NDK_TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin"
        export CC="$NDK_TOOLCHAIN/x86_64-linux-android${API}-clang"
        export CXX="$NDK_TOOLCHAIN/x86_64-linux-android${API}-clang++"
        export AR="$NDK_TOOLCHAIN/llvm-ar"
        export RANLIB="$NDK_TOOLCHAIN/llvm-ranlib"
        ;;
    ios-*-arm64_iphoneos|ios-*-arm64_iphonesimulator)
        # libsodium 1.0.18 config.sub (2019) doesn't know ios; arm-apple-darwin
 cross-compile mode.
        HOST="arm-apple-darwin"
        ;;
    ios-*-x86_64_iphonesimulator)
        HOST="x86_64-apple-darwin"
        ;;
    *)
        # Fallback: sniff from CC full path
        CC_VAL="${CC:-}"
        if echo "$CC_VAL" | grep -q 'linux-android'; then
            HOST=$(basename "$(echo "$CC_VAL" | awk '{print $1}')" | sed 's/[0-9]*-clang.*$//')
        elif echo "$CC_VAL" | grep -qE '(x86_64).*(simulator|ios)|(simulator|ios).*(x86_64)'; then
            HOST="x86_64-apple-darwin"
        elif echo "$CC_VAL" | grep -qiE '(arm64|aarch64).*(simulator|iphoneos|ios)|(simulator|iphoneos|ios).*(arm64|aarch64)'; then
            HOST="arm-apple-darwin"
        fi
        ;;
esac

echo "Using HOST='$HOST' CC='${CC:-}'"

mkdir -p "$PREFIX"
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

CONFIGURE_FLAGS=(
    "--disable-shared"
    "--enable-static"
    "--disable-debug"
    "--disable-dependency-tracking"
    "--with-pic"
    "--prefix=$PREFIX"
)
[ -n "$HOST" ] && CONFIGURE_FLAGS+=("--host=$HOST")

(cd "$BUILD_DIR" && "$SRC_DIR/configure" "${CONFIGURE_FLAGS[@]}")
JOBS=$(sysctl -n hw.logicalcpu 2>/dev/null || nproc 2>/dev/null || echo 4)
make -C "$BUILD_DIR" -j"$JOBS"
make -C "$BUILD_DIR" install
