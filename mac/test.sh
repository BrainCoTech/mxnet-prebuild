#!/bin/bash
set -e

# echo yellow
function echo_y () {
    local YELLOW="\033[1;33m"
    local RESET="\033[0m"
    echo -e "${YELLOW}$@${RESET}"
}

# remove
rm -rf *.exe

echo_y "test static library"
gcc -o static-test.exe ../test/main.c -I./include static/libmxnet_predict.a -lblas -lstdc++
./static-test.exe

echo_y "\ntest shared library"
gcc -o shared-test.exe ../test/main.c -I./include -L./shared -lmxnet_predict -lblas -lstdc++
./shared-test.exe
