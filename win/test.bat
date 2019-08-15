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
    call cl /I ..\test  ..\test\main.c      ^
            /I ..\mxnet\include\mxnet       ^
            dist\%ARCH%\shared\libmxnet.lib ^
            /link /out:test-shared.exe

    call :echo_y [windows] run test-shared.exe
    set PATH=%PATH%;%SCRIPT_DIR%\dist\%ARCH%\shared
    test-shared.exe

    call :clean
goto :eof
