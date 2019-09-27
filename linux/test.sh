#!/bin/bash
set -e
cd ${0%/*}
SCRIPT_DIR=$(pwd)

# echo yellow
function echo_y () { echo -e "\033[1;33m$@\033[0m" ; }

# remove
rm -rf *.exe

echo_y "[linux] test static library"
gcc -o static-test.exe  \
    ../test/main.c      \
    -Idist/include      \
    dist/static/libmxnet_predict.a  \
    -lm -lpthread -lrt -lstdc++
./static-test.exe

echo_y "\n[linux] test shared library"
gcc -o shared-test.exe ../test/main.c   \
    -Idist/include                      \
    -Ldist/shared -lmxnet_predict       \
    -lm -lpthread -lrt -lstdc++
LD_LIBRARY_PATH=dist/shared ./shared-test.exe
