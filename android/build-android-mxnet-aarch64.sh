#!/bin/bash
set -e
root=$(pwd)

# test building "arm64-v8a"
API="21"
PLATFORM="darwin-x86_64"

# export toolchain to PATH
export PATH="$PATH:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${PLATFORM}/bin"
export CC="aarch64-linux-android${API}-clang"       # arm64-v8a
export CXX="aarch64-linux-android${API}-clang++"    # arm64-v8a
OPENBLAS_ROOT="${root}/openblas/arm64-v8a"          # arm64-v8a

# build mxnet object file
cd ../mxnet/amalgamation/
make clean
make mxnet_predict-all.cc ANDROID=1 OPENBLAS_ROOT=${OPENBLAS_ROOT}

# modify mxnet_predict-all.cc
cat mxnet_predict-all.cc \
    | sed 's/#include <TargetConditionals.h>//' \
    | sed 's/#include <x86intrin.h>/#include <endian.h>/' \
    > tmp.cc
mv tmp.cc mxnet_predict-all.cc

# build mxnet_predict-all.o
make mxnet_predict-all.o ANDROID=1 OPENBLAS_ROOT=${OPENBLAS_ROOT}

# show result (architecture: aarch64)
objdump -f mxnet_predict-all.o
