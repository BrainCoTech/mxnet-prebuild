@echo off
setlocal
set SCRIPT_DIR=%~dp0
set ARCH=x64
goto :main

:: echo yellow
:echo_y
    echo.
    echo [93m%*[0m
goto :eof

:: clean files
:clean
    pushd %SCRIPT_DIR%
        del *.obj *.exe
    popd
goto :eof

:main
    call :clean

    call :echo_y Environment initialized for: '%ARCH%'
    call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %ARCH%

    call :echo_y [windows] build test with mxnet.dll
    call cl ..\test\main.c              ^
            /I ..\test                  ^
            /I mxnet\include\mxnet      ^
            mxnet\lib\libmxnet.lib      ^
            mxnet\lib\dmlc.lib          ^
            openblas\lib\openblas.lib   ^
            /link /out:test-shared.exe

    call :echo_y [windows] run test-shared.exe
    set PATH=%PATH%;%SCRIPT_DIR%\mxnet\bin
    test-shared.exe

    call :clean
goto :eof
