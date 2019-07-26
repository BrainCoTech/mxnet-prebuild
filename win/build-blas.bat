@echo off
setlocal
cd %~dp0

set ARCH=x64
set SCRIPT_DIR=%CD%
set OPENBLAS_ROOT=%SCRIPT_DIR%\..\openblas

goto :main

:echo_y
    echo [93m%*[0m
goto :eof

:echo_r
    echo [91m%*[0m
goto :eof

:check_install
    set CMD=%~1
    set PKG=%~2

    rem check command
    where %CMD% >nul 2>&1
    if %errorlevel% equ 0 (
        exit /b 0
    )

    echo.
    call :echo_r command '%CMD%' is not found
    call :echo_y choco install %PKG%

    rem check choco
    where choco >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        call :echo_r command 'choco' is not found
        call :echo_y Please install chocolatey at https://chocolatey.org/
        exit /b 1
    )

    rem check permission
    net session >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        call :echo_r Require admin permission to install package '%PKG%'
        call :echo_y Please reopen the terminal with admin permission
        exit /b 1
    )

    rem install package
    choco install %PKG% -y
goto :eof

:main
    rem check choco
    call :check_install clang-cl llvm
    call :check_install ninja ninja

    rem enable MSVC
    call :echo_y Environment initialized for: '%ARCH%'
    call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %ARCH%

    rem create openblas folder
    rmdir /s /q build\openblas openblas
    mkdir build\openblas

    pushd build\openblas
        call cmake %OPENBLAS_ROOT% -G "Ninja" ^
            -DCMAKE_C_COMPILER="clang-cl"     ^
            -DNOFORTRAN="ON"                  ^
            -DCMAKE_BUILD_TYPE="Release"      ^
            -DCMAKE_INSTALL_PREFIX="%SCRIPT_DIR%\openblas"

        call cmake --build . --config Release --target install
    popd

goto :eof
