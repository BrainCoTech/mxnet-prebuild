#!/bin/bash
set -e
root=$(pwd)

# Android SDK API Level (API 21 for Android 5.0)
API="21"

# color code
RED="\033[0;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# echo yellow
function echo_y () {
    echo -e "${YELLOW}$@${RESET}"
}

# echo red
function echo_r () {
    echo -e "${RED}$@${RESET}"
}

# clean
rm -rf dist
mkdir -p dist

# ENV: check Python 2.x
PY_VERSION=$(python -V 2>&1)
if [ -z "$(echo ${PY_VERSION} | grep 'Python 2.')" ]; then
    echo_r "[android] required Python 2.x, but your python is (${PY_VERSION})"
    exit 1
fi

# ENV: check NDK
if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo_r "[android] environment variable 'ANDROID_NDK_ROOT' need to be setup"
    exit 1
fi

# ENV: export toolchain platform to PATH
cd ${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt
PLATFORM=$(ls -1 | head -1)     # e.g. darwin-x86_64
if [ -z "$PLATFORM" ]; then
    echo_r "[android] get toolchain platform failed"
    exit 1
fi
export PATH="$PATH:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${PLATFORM}/bin"

# mxnet and blas root
MXNET_ROOT=${root}/../mxnet
BLAS_ROOT=${root}/openblas

# function: build
function build () {
    cd ${MXNET_ROOT}/amalgamation

    echo "[${ARCH}] AR = ${AR}"
    echo "[${ARCH}] CC = ${CC}"
    echo "[${ARCH}] CXX = ${CXX}"

    # CFLAGS
    CFLAGS="-std=c++11 -Wno-unknown-pragmas -Wall"
    CFLAGS+=" -DMSHADOW_USE_CBLAS=1"
    CFLAGS+=" -DMSHADOW_USE_SSE=0"
    CFLAGS+=" -DDISABLE_OPENMP=1"
    CFLAGS+=" -DMSHADOW_USE_CUDA=0"
    CFLAGS+=" -DMSHADOW_USE_MKL=0"
    CFLAGS+=" -DMSHADOW_RABIT_PS=0"
    CFLAGS+=" -DMSHADOW_DIST_PS=0"
    CFLAGS+=" -DDMLC_LOG_STACK_TRACE=0"
    CFLAGS+=" -DMSHADOW_FORCE_STREAM"
    CFLAGS+=" -DMXNET_USE_OPENCV=0"
    CFLAGS+=" -DMXNET_PREDICT_ONLY=1"
    CFLAGS+=" -DMSHADOW_USE_F16C=0"
    CFLAGS+=" -I${BLAS_ROOT}/${ARCH}"
    CFLAGS+=" -I${BLAS_ROOT}/${ARCH}/include"

    # clean
    echo_y "[${ARCH}] clean: remove nnvm.d dmlc.d mxnet_predict0.d mxnet_predict-all.cc mxnet_predict-all.o"
    rm -rf nnvm.d               \
        dmlc.d                  \
        mxnet_predict0.d        \
        mxnet_predict-all.cc    \
        mxnet_predict-all.o

    # nnvm.d
    echo_y "[${ARCH}] build nnvm.d"
    ./prep_nnvm.sh

    # dmlc.d
    echo_y "[${ARCH}] build dmlc.d"
    ${CXX} ${CFLAGS} -M -MT dmlc-minimum0.o         \
        -I${MXNET_ROOT}/3rdparty/dmlc-core/include  \
        -D__MIN__=0 dmlc-minimum0.cc > dmlc.d

    # mxnet_predict0.d
    echo_y "[${ARCH}] build mxnet_predict0.d"
    ${CXX} ${CFLAGS} -M -MT mxnet_predict0.o        \
        -I${MXNET_ROOT}                             \
        -I${MXNET_ROOT}/include                     \
        -I${MXNET_ROOT}/3rdparty/mshadow            \
        -I${MXNET_ROOT}/3rdparty/dmlc-core/include  \
        -I${MXNET_ROOT}/3rdparty/dmlc-core/src      \
        -I${MXNET_ROOT}/3rdparty/tvm/nnvm/include   \
        -I${MXNET_ROOT}/3rdparty/dlpack/include     \
        -D__MIN__=0 mxnet_predict0.cc > mxnet_predict0.d

    # add dmlc.d and nnvm.d to mxnet_predict0.d
    echo_y "[${ARCH}] add dmlc.d and nnvm.d to mxnet_predict0.d"
    cat dmlc.d >> mxnet_predict0.d
    cat nnvm.d >> mxnet_predict0.d

    # mxnet_predict-all.cc
    echo_y "[${ARCH}] build mxnet_predict-all.cc"
    python ./amalgamation.py    \
        mxnet_predict0.d        \
        dmlc-minimum0.cc        \
        nnvm.cc                 \
        mxnet_predict0.cc       \
        mxnet_predict-all.cc    \
        0 1                         # MIN=0 ANDROID=1

    # modify mxnet_predict-all.cc
    echo_y "[${ARCH}] modify mxnet_predict-all.cc"
    cat mxnet_predict-all.cc \
        | sed 's/#include <TargetConditionals.h>//' \
        | sed 's/#include <x86intrin.h>/#include <endian.h>/' \
        > tmp.cc
    mv tmp.cc mxnet_predict-all.cc

    # mxnet_predict-all.o
    echo_y "[${ARCH}] build mxnet_predict-all.o"
    ${CXX} ${CFLAGS} -fPIC \
        -c mxnet_predict-all.cc \
        -o ${root}/dist/mxnet_predict-all.o           # destination: ${root}/dist

    # merge openblas.a into libmxnet_predict.a
    echo_y "[${ARCH}] merge openblas.a into libmxnet_predict.a"
    cd ${root}/dist
    ${AR} x ${root}/openblas/${ARCH}/lib/*.dev.a      # generate openblas object files
    ${AR} rcs libmxnet_predict-android-${ARCH}.a *.o  # combine all object files to a static library

    # remove object files
    rm -rf *.o

    echo_y "[${ARCH}] libmxnet_predict-android-${ARCH}.a"
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
