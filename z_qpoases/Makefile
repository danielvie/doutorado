all: default

c: clean

default:
	cmake -B ./build
	cmake --build ./build
	./build/main

clean:
	rm -rf build