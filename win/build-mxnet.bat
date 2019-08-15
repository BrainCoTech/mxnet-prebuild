@echo off
setlocal enabledelayedexpansion
set ARCH=x64
cd %~dp0
set SCRIPT_DIR=%CD%
set MXNET_ROOT=%SCRIPT_DIR%\..\mxnet
goto :main

:: echo yellow
:echo_y
    echo.
    echo [93m%*[0m
goto :eof

:: clean
:clean
    pushd %MXNET_ROOT%
        call :echo_y [win][mxnet] reset mxnet
        call git reset --hard HEAD

        cd 3rdparty\dmlc-core
        call :echo_y [win][dmlc] reset mxnet\3rdparty\dmlc-core
        call git reset --hard HEAD
    popd
goto :eof

:main
    call :clean

    :: Update FindOpenBLAS.cmake
    call :echo_y [win][mxnet] Update cmake\Modules\FindOpenBLAS.cmake
    pushd %MXNET_ROOT%\cmake\Modules
        :: add "${OpenBLAS_HOME}/include/openblas" after "${OpenBLAS_HOME}/include"
        :: https://stackoverflow.com/a/4531177
        for /f "delims=" %%a in ('findstr /n "^" FindOpenBLAS.cmake') do (
            set "line=%%a"
            set "line=!line:*:=!"
            echo.!line!

            if "!line!" equ "  ${OpenBLAS_HOME}/include" (
                echo   ${OpenBLAS_HOME}/include/openblas
            )
        ) >> tmp.cmake
        move /y tmp.cmake FindOpenBLAS.cmake

        :: show diff
        call git diff
    popd

    :: enable MSVC
    call :echo_y Environment initialized for: '%ARCH%'
    call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %ARCH%

    :: create mxnet build folder
    rmdir /s /q build\mxnet dist
    mkdir       build\mxnet

    :: build mxnet
    pushd build\mxnet
        set OpenBLAS_HOME=%SCRIPT_DIR%\openblas

        :: cmake build
        call cmake %MXNET_ROOT% -A%ARCH%    ^
                -DUSE_CUDA=0                ^
                -DUSE_CUDNN=0               ^
                -DUSE_OPENCV=0              ^
                -DUSE_OPENMP=0              ^
                -DUSE_PROFILER=1            ^
                -DUSE_BLAS=open             ^
                -DUSE_LAPACK=0              ^
                -DUSE_DIST_KVSTORE=0        ^
                -DBUILD_CPP_EXAMPLES=0      ^
                -DUSE_MKL_IF_AVAILABLE=0

        call cmake --build . --config Release
    popd

    :: create dist folder
    mkdir dist\%ARCH%\shared

    :: merge dmlc and openblas into libmxnet
    call lib /nologo /out:dist\%ARCH%\shared\libmxnet.lib   ^
            build\mxnet\Release\libmxnet.lib                ^
            build\mxnet\3rdparty\dmlc-core\Release\dmlc.lib ^
            openblas\lib\openblas.lib

    :: copy dll
    xcopy build\mxnet\Release\libmxnet.dll dist\%ARCH%\shared\

    call :clean
goto :eof
