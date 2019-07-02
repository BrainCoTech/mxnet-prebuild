#!/bin/bash
set -e
root=$(pwd)

# Android SDK API Level (API 21 for Android 5.0)
API="21"

# clean
rm -rf dist
mkdir -p dist

# check NDK
if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "[android] environment variable 'ANDROID_NDK_ROOT' need to be setup"
    exit 1
fi

# check toolchain platform and export to PATH
cd ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt
PLATFORM=$(ls -1 | head -1)     # e.g. darwin-x86_64
if [ -z "$PLATFORM" ]; then
    echo "[android] get toolchain platform failed"
    exit 1
fi
export PATH="$PATH:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${PLATFORM}/bin"

# Makefile: remove hard-float flag
cd ${root}/../mxnet/amalgamation/
git checkout -- .
cat Makefile \
    | sed 's/-mhard-float -D_NDK_MATH_NO_SOFTFP=1//' \
    | sed 's/ -lm_hard//' \
    > tmp.mk
mv tmp.mk Makefile

# build function
function build () {
    echo "ARCH = ${ARCH}"
    echo "AR   = ${AR}"
    echo "CC   = ${CC}"
    echo "CXX  = ${CXX}"

    # build mxnet object file
    OPTIONS="ANDROID=1 OPENBLAS_ROOT=${root}/openblas/${ARCH}"
    cd ${root}/../mxnet/amalgamation/
    make clean
    make mxnet_predict-all.cc ${OPTIONS}

    # modify mxnet_predict-all.cc
    cat mxnet_predict-all.cc \
        | sed 's/#include <TargetConditionals.h>//' \
        | sed 's/#include <x86intrin.h>/#include <endian.h>/' \
        > tmp.cc
    mv tmp.cc mxnet_predict-all.cc

    # build mxnet_predict-all.o
    make mxnet_predict-all.o ${OPTIONS}

    # move mxnet_predict-all.o to dist
    mv mxnet_predict-all.o ${root}/dist

    # merge openblas into libmxnet_predict.a
    cd ${root}/dist
    ${AR} x ${root}/openblas/${ARCH}/lib/*.dev.a      # generate openblas object files
    ${AR} rcs libmxnet_predict-android-${ARCH}.a *.o  # combine all object files to a static library

    # remove object files
    rm -rf *.o
}

# 1. armeabi-v7a
export ARCH="armeabi-v7a"
export AR="arm-linux-androideabi-ar"
export CC="armv7a-linux-androideabi${API}-clang"
export CXX="armv7a-linux-androideabi${API}-clang++"
build

# 2. arm64-v8a
export ARCH="arm64-v8a"
export AR="aarch64-linux-android-ar"
export CC="aarch64-linux-android${API}-clang"
export CXX="aarch64-linux-android${API}-clang++"
build

# 3. x86
export ARCH="x86"
export AR="i686-linux-android-ar"
export CC="i686-linux-android${API}-clang"
export CXX="i686-linux-android${API}-clang++"
build

# 4. x86_64
export ARCH="x86_64"
export AR="x86_64-linux-android-ar"
export CC="x86_64-linux-android${API}-clang"
export CXX="x86_64-linux-android${API}-clang++"
build

# Makefile: reset changed files in MXNet
cd ${root}/../mxnet/amalgamation/
git checkout -- .
