#include <iostream>
#include "MatrixMath.h"

int main() {

    MatrixData M;
    M.rows = 5;
    M.cols = 3;

    M.values.push_back(-0.0023027);
    M.values.push_back(-0.0045131);
    M.values.push_back(-0.0045605);
    M.values.push_back(0.0023013);
    M.values.push_back(0.0045863);
    M.values.push_back(0.0023314);
    M.values.push_back(-0.0022593);
    M.values.push_back(-0.0090792);
    M.values.push_back(-0.0022091);
    M.values.push_back(0.0022807);
    M.values.push_back(-0.028284);
    M.values.push_back(0.028502);
    M.values.push_back(-0.056414);
    M.values.push_back(0.029898);
    M.values.push_back(-0.029624);
    
    matrix_print(M);


    float result[5];
    matrix_multiply_vector3(M, 1, 1, 1, result);

    std::cout << "result: ";
    for (size_t i = 0; i < 5; i++)
    {
        printf("%f ", result[i]);
    }
    printf(";");
    

    return 0;
}
