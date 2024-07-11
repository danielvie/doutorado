cmake_minimum_required(VERSION 3.20)
project(test)

set(sources
    src/main.cpp
)

add_executable(main
    ${sources}
)