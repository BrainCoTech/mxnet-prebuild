#!/bin/bash

set -e
root=$(pwd)
rm -rf release
mkdir -p release

# mxnet version
cd $root/mxnet
MXNET_VERSION=$(git rev-parse --short HEAD)

cd $root
echo $MXNET_VERSION > release/MXNET_VERSION
cp mxnet/include/mxnet/c_predict_api.h   release
cp mac/shared/libmxnet_predict.dylib     release/libmxnet_predict-mac-x86_64.dylib
cp mac/static/libmxnet_predict.a         release/libmxnet_predict-mac-x86_64.a
cp ios/dist/*                            release/
cp android/dist/*                        release/
