#!/bin/bash
set -e

# echo yellow
function echo_y () {
    local YELLOW="\033[1;33m"
    local RESET="\033[0m"
    echo -e "${YELLOW}$@${RESET}"
}

# remove
rm -rf include src build dist
mkdir -p include src build dist

cd ..
root=$(pwd)

# copy header
echo_y "copy header"
cp mxnet/include/mxnet/c_predict_api.h  ios/include

# check openblas
echo_y "check openblas"
if [ -z "$(brew list | grep openblas)" ]; then
    brew install openblas
fi

# brew info openblas
# openblas: stable 0.3.6 (bottled), HEAD [keg-only]
# Optimized BLAS library
# https://www.openblas.net/
# /usr/local/Cellar/openblas/0.3.6_1 (21 files, 120MB)

echo_y "generate mxnet_predict-all.cc"
cd mxnet/amalgamation
make clean
make mxnet_predict-all.cc

# 1. change "cblas.h" to "Accelerate/Accelerate.h"
c1="#include <cblas.h>"
r1="#include <Accelerate\/Accelerate.h>"

# 2. delete "emmintrin.h"
c2="#include <emmintrin.h>"

# 3. delete "x86intrin.h" and add "execinfo.h" and "shared_mutex"
c3="#include <x86intrin.h>"
r3="#include <execinfo.h>
#include <shared_mutex>"

# 4. define MSHADOW_USE_SSE 0
c4="#define MSHADOW_USE_SSE 1"
r4="#define MSHADOW_USE_SSE 0"

# 5. define MSHADOW_USE_F16C 0
c5="#ifndef MSHADOW_USE_F16C
.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*
#endif"
r5="#define MSHADOW_USE_F16C 0"

# 6. delete all the code in MSHADOW_USE_MKL
c6="#if MSHADOW_USE_MKL == 0
.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*
.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*
.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*
.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*
.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*
.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*
.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*
.*\n.*\n.*
#endif  \/\/ MSHADOW_USE_MKL == 0"

# modify mxnet_predict-all.cc
echo_y "modify mxnet_predict-all.cc"
cat mxnet_predict-all.cc \
    | perl -0pe "s/${c1}/${r1}/"  \
    | perl -0pe "s/${c2}//"       \
    | perl -0pe "s/${c3}/${r3}/"  \
    | perl -0pe "s/${c4}/${r4}/"  \
    | perl -0pe "s/${c5}/${r5}/"  \
    | perl -0pe "s/${c6}//"       \
    > tmp.cc

# overwite mxnet_predict-all.cc
mv tmp.cc mxnet_predict-all.cc

# copy the source code
mv mxnet_predict-all.cc $root/ios/src

# cmake build
cd $root/ios
cmake -S . -B "build" -G "Xcode"                    \
    -DCMAKE_SYSTEM_NAME="iOS"                       \
    -DCMAKE_OSX_ARCHITECTURES="arm64;arm64e;x86_64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10"              \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/build"           \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH="NO"   \
    -DCMAKE_IOS_INSTALL_COMBINED="YES"

cmake --build "build" --config "Release" --target "install" \
      -- ALWAYS_SEARCH_USER_PATHS="NO"       \
         BITCODE_GENERATION_MODE="bitcode"   \
         OTHER_CFLAGS="-fembed-bitcode"

# iphonesimulator: Debug 164MB   / Release 23MB    (x86_64)
# iphoneos:        Debug 848.5MB / Release 107.2MB (arm64 + arm64e)

# arm64  (Release: 51.2MB)
# arm64e (Release: 56.1MB)
# x86_64 (Release: 23.3MB)
ARCHS="arm64 arm64e x86_64"
for ARCH in ${ARCHS}
do
    lipo -thin ${ARCH} build/lib/libmxnet_predict.a \
         -output dist/libmxnet_predict-ios-${ARCH}.a
done
