#!/bin/bash
set -e
root=$(pwd)

rm -rf dist
mkdir -p dist

# Android SDK API Level (API 21 for Android 5.0)
API="21"

# check NDK
if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "[android] environment variable 'ANDROID_NDK_ROOT' need to be setup"
    exit 1
fi

# check toolchain platform
cd ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt
PLATFORM=$(ls -1 | head -1)     # e.g. darwin-x86_64
if [ -z "$PLATFORM" ]; then
    echo "[android] get toolchain platform failed"
    exit 1
fi

# export toolchain to PATH (for CC and CXX)
export PATH="$PATH:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${PLATFORM}/bin"

ARCHS=(
    armeabi-v7a
    arm64-v8a
    x86
    x86_64)

CCS=(
    armv7a-linux-androideabi${API}-clang   # armeabi-v7a
    aarch64-linux-android${API}-clang      # arm64-v8a
    i686-linux-android${API}-clang         # x86
    x86_64-linux-android${API}-clang)      # x86_64

for i in {0..3}
do
    ARCH=${ARCHS[$i]}
    export CC=${CCS[$i]}
    export CXX=${CC}++

    # build mxnet object file
    cd ${root}/../mxnet/amalgamation
    OPENBLAS_ROOT="${root}/openblas/${ARCH}"

    make clean
    make mxnet_predict-all.cc ANDROID=1 OPENBLAS_ROOT=${OPENBLAS_ROOT}

    # modify mxnet_predict-all.cc
    cat mxnet_predict-all.cc \
        | sed 's/#include <TargetConditionals.h>//' \
        | sed 's/#include <x86intrin.h>/#include <endian.h>/' \
        > tmp.cc
    mv tmp.cc mxnet_predict-all.cc

    # build object file
    make mxnet_predict-all.o ANDROID=1 OPENBLAS_ROOT=${OPENBLAS_ROOT}

    # move 'mxnet_predict-all.o' to dist
    mv mxnet_predict-all.o ${root}/dist

    cd ${root}/dist
    ar x ${root}/openblas/${ARCH}/lib/*.dev.a       # generate openblas object files
    ar rcs libmxnet_predict-android-${ARCH}.a *.o   # combine all object files to a static library

    # remove object files
    rm -rf *.o
done
