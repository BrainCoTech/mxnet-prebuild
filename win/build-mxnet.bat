@echo off
setlocal
set ARCH=x64
cd %~dp0
set SCRIPT_DIR=%CD%
set MXNET_ROOT=%SCRIPT_DIR%\..\mxnet
goto :main

:: echo yellow
:echo_y
    echo [93m%*[0m
goto :eof

:: clean
:clean
    pushd %MXNET_ROOT%
        :: clean mxnet
        call git reset --hard HEAD

        :: clean dmlc
        cd 3rdparty\dmlc-core
        call git reset --hard HEAD
    popd
goto :eof

:main
    call :clean

    :: Update FindOpenBLAS.cmake
    call :echo_y Update cmake\Modules\FindOpenBLAS.cmake
    pushd %MXNET_ROOT%
        :: TODO: don't overwrite the file directly
        call xcopy /y %SCRIPT_DIR%\FindOpenBLAS.cmake cmake\Modules\FindOpenBLAS.cmake
        call git diff
    popd

    :: enable MSVC
    call :echo_y Environment initialized for: '%ARCH%'
    call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %ARCH%

    :: create mxnet build folder
    rmdir /s /q build\mxnet mxnet
    mkdir       build\mxnet

    :: build mxnet
    pushd build\mxnet
        set OpenBLAS_HOME=%SCRIPT_DIR%\openblas

        :: cmake build
        call cmake %MXNET_ROOT% -Ax64       ^
                -DUSE_CUDA=0                ^
                -DUSE_CUDNN=0               ^
                -DUSE_OPENCV=0              ^
                -DUSE_OPENMP=0              ^
                -DUSE_PROFILER=1            ^
                -DUSE_BLAS=open             ^
                -DUSE_LAPACK=0              ^
                -DUSE_DIST_KVSTORE=0        ^
                -DBUILD_CPP_EXAMPLES=0      ^
                -DUSE_MKL_IF_AVAILABLE=0    ^
                -DCMAKE_INSTALL_PREFIX=%SCRIPT_DIR%\mxnet

        call cmake --build . --config Release --target install
    popd

    call :clean
goto :eof
