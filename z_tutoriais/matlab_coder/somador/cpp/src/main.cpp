#include <iostream>
#include "fun_soma.h"

int main(int argc, char const *argv[])
{
	int a = 3;
	int b = 4;

	printf("soma(%d,%d): %d\n", a, b, fun_soma(a,b));
	
	return 0;
}