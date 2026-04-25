file(GLOB_RECURSE srcs "*.c" "*.cpp" "src/*.c" "src/*.cpp")

idf_component_register(SRCS "main.cpp" "${srcs}"
                       INCLUDE_DIRS "./include" "./src" "./src/proto")
