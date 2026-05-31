#!/bin/bash
# Cross-compile libsodium from source (skips 'make check').
# Usage: libsodium.sh <src_dir> <install_prefix>
# Infers the cross-compilation --host from $CC or $CIBW_ARCHS.
set -euo pipefail

SRC_DIR="$1"
PREFIX="$2"

HOST=""

# Prefer CIBW_ARCHS (most reliable); fall back to parsing CC basename
ARCH="${CIBW_ARCHS:-}"
CC_VAL="${CC:-}"

if [ -n "$ARCH" ]; then
    case "$ARCH" in
        arm64_iphoneos|arm64_iphonesimulator) HOST="aarch64-apple-darwin" ;;
        x86_64_iphonesimulator)               HOST="x86_64-apple-darwin" ;;
        arm64_v8a)                            HOST="aarch64-linux-android" ;;
        x86_64)
            echo "$CC_VAL" | grep -q 'android' && HOST="x86_64-linux-android" ;;
    esac
fi

if [ -z "$HOST" ] && [ -n "$CC_VAL" ]; then
    CC_BASE=$(basename "$CC_VAL")
    if echo "$CC_BASE" | grep -q 'linux-android'; then
        HOST=$(echo "$CC_BASE" | sed 's/[0-9]*-clang$//')
    elif echo "$CC_VAL" | grep -q 'x86_64'; then
        HOST="x86_64-apple-darwin"
    elif echo "$CC_VAL" | grep -qE 'arm64|aarch64'; then
        HOST="aarch64-apple-darwin"
    fi
fi

mkdir -p "$PREFIX"
BUILD_DIR=$(mktemp -d)

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
# Intentionally skip 'make check' — cannot run cross-compiled binaries on the build host
make -C "$BUILD_DIR" install
