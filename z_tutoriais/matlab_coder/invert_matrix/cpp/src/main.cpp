#include <iostream>
#include "fun_invert_matrix3.h"

int main(int argc, char const *argv[])
{

	double A[9] = {3.,2.,4.,5.,2.,1.,9.,3.,2.};
	double Ai[9];

	// void fun_invert_matrix3(const double A[9], double Ai[9])
	fun_invert_matrix3(A, Ai);

	printf("%.4f, %.4f, %.4f\n", Ai[0], Ai[1], Ai[2]);
	printf("%.4f, %.4f, %.4f\n", Ai[3], Ai[4], Ai[5]);
	printf("%.4f, %.4f, %.4f\n", Ai[6], Ai[7], Ai[8]);

	std::cout << "-----------------------------------------\n";
	std::cout << "hello\n";
	return 0;
}