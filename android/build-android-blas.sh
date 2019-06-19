#!/bin/bash
set -e
root=$(pwd)

# Android SDK API Level (API 21 for Android 5.0)
API="21"

# clean build folder
rm -rf openblas

# check NDK
if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "[android] environment variable 'ANDROID_NDK_ROOT' need to be setup"
    exit 1
fi

# check toolchain platform
cd ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt
PLATFORM=$(ls -1 | head -1)     # e.g. darwin-x86_64
echo "PLATFORM: ${PLATFORM}"
if [ -z "$PLATFORM" ]; then
    echo "[android] get toolchain platform failed"
    exit 1
fi

# export toolchain to PATH
export PATH="$PATH:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${PLATFORM}/bin"

# build openblas
cd ${root}/../openblas

# 1. armeabi-v7a
make clean
make -j4 ONLY_CBLAS="1" HOSTCC="gcc" ARM_SOFTFP_ABI="1" TARGET="ARMV7" \
    AR="arm-linux-androideabi-ar" \
    CC="armv7a-linux-androideabi${API}-clang"
make PREFIX="${root}/openblas/armeabi-v7a/" install

# 2. arm64-v8a
make clean
make -j4 ONLY_CBLAS="1" HOSTCC="gcc" TARGET="ARMV8" \
    AR="aarch64-linux-android-ar" \
    CC="aarch64-linux-android${API}-clang"
make PREFIX="${root}/openblas/arm64-v8a/" install

# 3. x86
make clean
make -j4 ONLY_CBLAS="1" HOSTCC="gcc" BINARY="32" \
    AR="i686-linux-android-ar" \
    CC="i686-linux-android${API}-clang"
make PREFIX="${root}/openblas/x86/" install

# 4. x86_64
make clean
make -j4 ONLY_CBLAS="1" HOSTCC="gcc" \
    AR="x86_64-linux-android-ar" \
    CC="x86_64-linux-android${API}-clang"
make PREFIX="${root}/openblas/x86_64/" install
