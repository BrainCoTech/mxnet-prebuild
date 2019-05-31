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
cp mxnet/include/mxnet/c_predict_api.h          release
cp mac/shared/libmxnet_predict.dylib            release/libmxnet_predict-mac.dylib
cp mac/static/libmxnet_predict.a                release/libmxnet_predict-mac.a
cp ios/dist/iphoneos/libmxnet_predict.a         release/libmxnet_predict-ios-iphone.a
cp ios/dist/iphonesimulator/libmxnet_predict.a  release/libmxnet_predict-ios-simulator.a
cp ios/dist/universal/libmxnet_predict.a        release/libmxnet_predict-ios-universal.a
