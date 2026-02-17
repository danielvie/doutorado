cmake_minimum_required(VERSION 3.20.0)
project(main LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17)

file(GLOB sources "src/*.cpp")
add_executable(main ${sources})