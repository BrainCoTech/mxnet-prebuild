#!/bin/bash

set -e

# echo yellow
function echo_y () {
    local YELLOW="\033[1;33m"
    local RESET="\033[0m"
    echo -e "${YELLOW}$@${RESET}"
}

# remove
rm -rf include shared static *.exe
mkdir  include shared static

root=$(pwd)/..
cd $root

echo_y "check openblas"
if [ -z "$(brew list | grep openblas)" ]; then
    brew install openblas
fi

# brew info openblas
# openblas: stable 0.3.6 (bottled), HEAD [keg-only]
# Optimized BLAS library
# https://www.openblas.net/
# /usr/local/Cellar/openblas/0.3.6_1 (21 files, 120MB)

echo_y "\nBuild static and shared library"
cd mxnet/amalgamation
make clean
make

echo_y "copy header and library"
cd $root
cp mxnet/include/mxnet/c_predict_api.h    mac/include
cp mxnet/amalgamation/libmxnet_predict.a  mac/static
cp mxnet/lib/libmxnet_predict.so          mac/shared

cd mac
echo_y "\ntest static library"
gcc -o static-test.exe test.c -I./include static/libmxnet_predict.a -lblas -lstdc++
./static-test.exe

echo_y "\ntest shared library"
gcc -o shared-test.exe test.c -I./include -L./shared -lmxnet_predict -lblas -lstdc++
./shared-test.exe
