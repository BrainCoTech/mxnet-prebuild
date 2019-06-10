#!/bin/bash
set -e
root=$(pwd)

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
echo "PLATFORM: ${PLATFORM}"
if [ -z "$PLATFORM" ]; then
    echo "[android] get toolchain platform failed"
    exit 1
fi

# export toolchain to PATH
export PATH="$PATH:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${PLATFORM}/bin"

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

cd ${root}/../mxnet/amalgamation

# 1. armv7a
make clean
make libmxnet_predict.a ANDROID=1                \
    OPENBLAS_ROOT="${root}/openblas/armv7a"      \
    AR="arm-linux-androideabi-ar"                \
    CC="armv7a-linux-androideabi${API}-clang"
mkdir -p ${root}/mxnet/armv7a
mv libmxnet_predict.a ${root}/mxnet/armv7a

# 2. arm64-v8a
make clean
make libmxnet_predict.a ANDROID=1               \
    OPENBLAS_ROOT="${root}/openblas/arm64-v8a"  \
    AR="aarch64-linux-android-ar"               \
    CC="aarch64-linux-android${API}-clang"
mkdir -p ${root}/mxnet/arm64-v8a
mv libmxnet_predict.a ${root}/mxnet/arm64-v8a

# 3. x86
make clean
make libmxnet_predict.a ANDROID=1               \
    OPENBLAS_ROOT="${root}/openblas/x86"        \
    AR="i686-linux-android-ar"                  \
    CC="i686-linux-android${API}-clang"
mkdir -p ${root}/mxnet/x86
mv libmxnet_predict.a ${root}/mxnet/x86

# 4. x86_64
make clean
make libmxnet_predict.a ANDROID=1               \
    OPENBLAS_ROOT="${root}/openblas/x86_64"     \
    AR="x86_64-linux-android-ar"                \
    CC="x86_64-linux-android${API}-clang"
mkdir -p ${root}/mxnet/x86_64
mv libmxnet_predict.a ${root}/mxnet/x86_64
