#include <iostream>
#include "fun_quadprog.h"

// funcao para imprimir linha com entrada double
void print(const double value){
	printf("    %6.4f\n", value);
}

// funcao para imprimir linha com valor char*
void print(const char *value){
	printf("%s\n", value);
}

int main(int argc, char const *argv[])
{

	// void fun_quadprog(const double H[9], const double f[3], const double A[3],
    //               double b, const double lb[3], const double x0[3], double x[3],
    //               double *fval, double *exitflag)


	double H[9]  = { 1, -1,  1,
	                -1,  2, -2,
				 	 1, -2,  4};

	double f[3]  = {-7, -3, -9};

	double A[3]  = {1, 1, 1};

	double b     = 3;
	double lb[3] = {0,0,0};
	double x0[3] = {0,0,0};
	double x[3];
	double fval;
	double exitflag;

	fun_quadprog(H, f, A, b, lb, x0, x, &fval, &exitflag);

	print("\n");
	print("x:");
	print(x[0]);
	print(x[1]);
	print(x[2]);
	print("\n");
	
	print("fval:");
	print(fval);
	print("\n");
	
	print("exitflag:");
	print(exitflag);

	std::cout << "-----------------------------------------\n";
	std::cout << "hello\n";
	return 0;
}
