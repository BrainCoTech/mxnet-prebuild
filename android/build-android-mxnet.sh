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

# export toolchain to PATH (for AR, CC, CXX, ...)
export PATH="$PATH:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${PLATFORM}/bin"

ARCHS=(
    armv7a
    arm64-v8a
    x86
    x86_64)

ARS=(
    arm-linux-androideabi-ar    # armv7a
    aarch64-linux-android-ar    # arm64-v8a
    i686-linux-android-ar       # x86
    x86_64-linux-android-ar)    # x86_64

CCS=(
    armv7a-linux-androideabi${API}-clang   # armv7a
    aarch64-linux-android${API}-clang      # arm64-v8a
    i686-linux-android${API}-clang         # x86
    x86_64-linux-android${API}-clang)      # x86_64

for i in {0..3}
do
    ARCH=${ARCHS[$i]}
    export AR=${ARS[$i]}
    export CC=${CCS[$i]}
    export CXX=${CC}++

    # build mxnet object file
    cd ${root}/../mxnet/amalgamation
    make clean
    make mxnet_predict-all.o ANDROID=1 OPENBLAS_ROOT="${root}/openblas/${ARCH}"

    # move 'mxnet_predict-all.o' to dist
    mv mxnet_predict-all.o ${root}/dist

    cd ${root}/dist
    ${AR} x ${root}/openblas/${ARCH}/lib/*.dev.a  # generate openblas object files
    ${AR} rcs libmxnet_predict-${ARCH}.a *.o      # combine all object files to a static library

    # remove object files
    rm -rf *.o
done

# Makefile Config:
# OPENBLAS_ROOT = /Users/zlargon/BrainCo/mxnet-prebuild/android/openblas/arm64-v8a
# ANDROID = 1
# MIN = 0
# DEFS = -DMSHADOW_USE_CBLAS=1
#        -DMSHADOW_USE_SSE=0
#        -DDISABLE_OPENMP=1
#        -DMSHADOW_USE_CUDA=0
#        -DMSHADOW_USE_MKL=0
#        -DMSHADOW_RABIT_PS=0
#        -DMSHADOW_DIST_PS=0
#        -DDMLC_LOG_STACK_TRACE=0
#        -DMSHADOW_FORCE_STREAM
#        -DMXNET_USE_OPENCV=0
#        -DMXNET_PREDICT_ONLY=1
#        -DMSHADOW_USE_F16C=0
# MXNET_ROOT = /Users/zlargon/BrainCo/mxnet-prebuild/mxnet/amalgamation/..
# TPARTYDIR = /Users/zlargon/BrainCo/mxnet-prebuild/mxnet/amalgamation/../3rdparty
# CFLAGS = -std=c++11 -Wno-unknown-pragmas -Wall
#          -DMSHADOW_USE_CBLAS=1
#          -DMSHADOW_USE_SSE=0
#          -DDISABLE_OPENMP=1
#          -DMSHADOW_USE_CUDA=0
#          -DMSHADOW_USE_MKL=0
#          -DMSHADOW_RABIT_PS=0
#          -DMSHADOW_DIST_PS=0
#          -DDMLC_LOG_STACK_TRACE=0
#          -DMSHADOW_FORCE_STREAM
#          -DMXNET_USE_OPENCV=0
#          -DMXNET_PREDICT_ONLY=1
#          -DMSHADOW_USE_F16C=0
#          -I/Users/zlargon/BrainCo/mxnet-prebuild/android/openblas/arm64-v8a
#          -I/Users/zlargon/BrainCo/mxnet-prebuild/android/openblas/arm64-v8a/include
#          -mhard-float -D_NDK_MATH_NO_SOFTFP=1 -O3
# LDFLAGS = -L/Users/zlargon/BrainCo/mxnet-prebuild/android/openblas/arm64-v8a
#           -L/Users/zlargon/BrainCo/mxnet-prebuild/android/openblas/arm64-v8a/lib
#           -lopenblas
#           -Wl,--no-warn-mismatch -lm_hard
# USE_F16C =
# EMCC = emcc
# CC = aarch64-linux-android21-clang
# CXX = aarch64-linux-android21-clang++
# AR = aarch64-linux-android-ar
