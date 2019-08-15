@echo off
setlocal
cd %~dp0
set SCRIPT_DIR=%CD%
set ARCH=x64
set LIB_TYPE=shared
goto :main

:: echo yellow
:echo_y
    echo.
    echo [93m%*[0m
goto :eof

:main
    set RELEASE_NAME=libmxnet_predict-win-%ARCH%-%LIB_TYPE%

    :: create release folder
    rmdir /s /q release
    mkdir release\%RELEASE_NAME%

    :: write mxnet's git version to release folder
    pushd ..\mxnet
        call git rev-parse --short HEAD > %SCRIPT_DIR%\release\MXNET_VERSION
    popd

    xcopy win\dist\%ARCH%\%LIB_TYPE%\* release\%RELEASE_NAME%

    :: zip release folder
    pushd release
        :: TODO: check 7z command
        call 7z a %RELEASE_NAME%.zip %RELEASE_NAME%
        rmdir /s /q %RELEASE_NAME%
    popd

goto :eof
