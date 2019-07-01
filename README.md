# mxnet-prebuild

# clone project with submodule

```bash
git clone --recursive https://github.com/BrainCoTech/mxnet-prebuild.git

or

git clone https://github.com/BrainCoTech/mxnet-prebuild.git
git submodule update --init --recursive
```

# macOS

```bash
cd mac
./build-mac.sh
```

# iOS

```bash
cd ios
./build-ios.sh
```

# Android

```bash
cd android
./build-android-blas.sh
./build-android-mxnet.sh
```
