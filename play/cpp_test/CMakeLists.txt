cmake_minimum_required(VERSION 3.20.0)
project(test)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 23)

file(GLOB sources src/*.cpp lib/*.cpp)
add_executable(test ${sources})

target_include_directories(test PRIVATE
  include
  lib
)