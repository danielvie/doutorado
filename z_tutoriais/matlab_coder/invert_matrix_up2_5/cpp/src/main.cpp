#include <cstdio>
#include "fun_invert_matrix_up2_5.h"

void print_matriz(const double A[], const int A_size[2])
{
	int lin = A_size[0];
	int col = A_size[1];
	int idx;

	for (int i = 0; i < lin; i++) {
		for (int j = 0; j < col; j++) {
			idx = i*lin + j;
			printf("%8.4f ", A[idx]);
		}
		printf("\n");
	}
}

int main(int argc, char const *argv[])
{
	

	/* DECLARACAO DE VARIAVEIS */

	// dados inverter matriz 5x5
	double A_data[25] = {3,2,4,4,5,
						 5,2,1,6,3,
						 9,3,2,1,9,
						 3,5,12,5,7,
						 9,14,2,1,5};

	double Ai_data[25];
	int A_size[2] = {5,5};

	// void fun_invert_matrix_up2_5(const double A_data[], const int A_size[2], 
	//								double Ai_data[], int Ai_size[2])

	/* CALCULANDO INVERSA MATRIZ 5x5 */
	fun_invert_matrix_up2_5(A_data, A_size, Ai_data, A_size);
	
	printf("\n");
	printf("==============================================\n");
	printf("inversa matriz 5x5\n");
	printf("----------------------------------------------\n");
	printf("\n");

	printf("matriz A:\n\n");
	print_matriz(A_data, A_size);
	printf("\n");
	printf("matriz Ai:\n\n");
	print_matriz(Ai_data, A_size);

	printf("\n----------------------------------------------\n\n");

	/* CALCULANDO INVERSA MATRIZ 2x2 COM A MESMA FUNCAO */

	// invertendo matriz 2x2 com a mesma funcao
	A_data[0] = 3.; A_data[1] = 2.;
	A_data[2] = 5.; A_data[3] = 2.;

	A_size[0] = 2;
	A_size[1] = 2;

	fun_invert_matrix_up2_5(A_data, A_size, Ai_data, A_size);
	
	printf("\n");
	printf("==============================================\n");
	printf("inversa matriz 2x2\n");
	printf("----------------------------------------------\n");
	printf("\n");

	printf("matriz A:\n\n");
	print_matriz(A_data, A_size);
	printf("\n");
	printf("matriz Ai:\n\n");
	print_matriz(Ai_data, A_size);

	printf("\n----------------------------------------------\n\n");

	return 0;
}