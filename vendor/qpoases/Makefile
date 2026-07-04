all: default

c: clean

default:
	cmake -B ./build
	cmake --build ./build
	./build/debug/main.exe

clean:
	rm -rf build