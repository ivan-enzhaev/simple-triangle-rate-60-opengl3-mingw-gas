cmake_minimum_required(VERSION 3.21)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug") # "Debug" or "Release"
endif()

project(simple-triangle-rate-60-opengl3-mingw-gas LANGUAGES C ASM)

add_executable(app WIN32 src/main.S)

target_compile_options(app PRIVATE
    $<$<CONFIG:Debug>:-g>
)

target_link_options(app PRIVATE
    -nostdlib
    $<$<CONFIG:Release>:-s>
    -Wl,-e,main
    -Wl,--subsystem,windows
)

target_link_libraries(app PRIVATE kernel32 user32 gdi32 opengl32)