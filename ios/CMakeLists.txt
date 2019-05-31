cmake_minimum_required(VERSION 3.14)

set(targer_name "mxnet_predict")

# Project Info
project(
    ${targer_name}              # projectName
    VERSION 0.0.1               # [VERSION major[.minor[.patch[.tweak]]]]
    LANGUAGES C CXX             # [LANGUAGES languageName ...]
)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON) # -fPIC, -fPIE

add_library(
    ${targer_name}              # create a target as a library
    # SHARED/STATIC             # ignore library type because it will be decided by 'BUILD_SHARED_LIBS'
    src/mxnet_predict-all.cc    # source code
)
target_include_directories(
    ${targer_name}              # include directories to target
    PUBLIC include              # public header
)
