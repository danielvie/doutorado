cmake_minimum_required(VERSION 3.20.0)
project(qpOASISexample)

set(CMAKE_CXX_STANDARD 23)

include_directories(src/qpOASES/include)
include_directories(src)

file(GLOB mySources CONFIGURE_DEPENDS "src/*.cpp" "src/qpOASES/src/*.cpp")
add_executable(main ${mySources})