cmake_minimum_required(VERSION 3.20)

project(DhQuant VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include("${CMAKE_CURRENT_SOURCE_DIR}/assets/cmake/EuineoSdk.cmake")

add_executable(dhquant_dashboard
    src/gui/main.cpp
    src/gui/dhquant_dashboard.cpp
)

target_compile_options(dhquant_dashboard PRIVATE
    $<$<CXX_COMPILER_ID:AppleClang,Clang,GNU>:-Wall -Wextra -Wpedantic>
)

euineo_configure_app(dhquant_dashboard)
