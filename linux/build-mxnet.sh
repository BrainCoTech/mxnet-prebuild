#!/bin/bash
set -e
cd ${0%/*}
SCRIPT_DIR=$(pwd)
OPENBLAS_ROOT=${SCRIPT_DIR}/openblas
MXNET_ROOT=${SCRIPT_DIR}/../mxnet

# colorful echo functions
function echo_y() { echo -e "\033[1;33m$@\033[0m" ; }   # yellow
function echo_r() { echo -e "\033[0;31m$@\033[0m" ; }   # red

# create dist folder
rm -rf dist
mkdir -p dist/include dist/static dist/shared

# build mxnet
echo_y "[linux] build mxnet_predict-all.o"
cd ${MXNET_ROOT}/amalgamation
make clean
make OPENBLAS_ROOT=${OPENBLAS_ROOT}

# 1. static library
echo_y "[linux] generate static library"
cd ${SCRIPT_DIR}/dist/static
ar rcs libmxnet_predict.a       \
    ${OPENBLAS_ROOT}/obj/*.o    \
    ${MXNET_ROOT}/amalgamation/mxnet_predict-all.o

# 2. shared library
echo_y "[linux] generate shared library"
cd ${SCRIPT_DIR}/dist/shared
gcc -shared -fPIC -lstdc++ -lm -lrt -lpthread       \
    ${OPENBLAS_ROOT}/obj/*.o                        \
    ${MXNET_ROOT}/amalgamation/mxnet_predict-all.o  \
    -o libmxnet_predict.so

# 3. copy header
echo_y "[linux] copy header"
cp -v ${MXNET_ROOT}/include/mxnet/c_predict_api.h ${SCRIPT_DIR}/dist/include
