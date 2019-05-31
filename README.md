# mxnet-prebuild
* clone mxnet repository recursively.
## OSX
* check permissions to brew to install openblas `sudo chown -R $(whoami) /usr/local/share/man/man5`
* give permissions to brew to install openblas `chmod u+w /usr/local/share/man/man5`
* install necessary dependencies
```
brew update
brew install pkg-config
brew install graphviz
brew install openblas
brew tap homebrew/core
brew install opencv

# If building with MKLDNN
brew install llvm
```
* make project
```
cp make/osx.mk ./config.mk
echo "USE_BLAS = openblas" >> ./config.mk
echo "ADD_CFLAGS += -I/usr/local/opt/openblas/include" >> ./config.mk
echo "ADD_LDFLAGS += -L/usr/local/opt/openblas/lib" >> ./config.mk
echo "ADD_LDFLAGS += -L/usr/local/lib/graphviz/" >> ./config.mk
make -j$(sysctl -n hw.ncpu)
```
