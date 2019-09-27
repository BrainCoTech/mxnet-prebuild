#!/bin/bash
set -e
cd ${0%/*}
SCRIPT_DIR=$(pwd)
OPENBLAS_ROOT=${SCRIPT_DIR}/../openblas

# create build folder
rm -rf openblas

# build openblas
pushd ${OPENBLAS_ROOT}
    make clean
    make NO_FORTRAN=1
    make install PREFIX=${SCRIPT_DIR}/openblas
popd

# generate object files
mkdir -p openblas/obj
cd openblas/obj
ar x ../lib/libopenblas.a
