#include <iostream>
#include <vector>
#include <string>
#include "Matrix.h"

// --- Main function for demonstration ---
int main() {

    // --- Test Cases for String Parsing and Matrix Creation ---
    // std::string str_matrix_A = "2;3;1,2,3,4,5,6;";          // 2x3 matrix
    std::string str_matrix_A = "2;4;1,2,3,4,5,6;";          // 2x3 matrix
    std::string str_matrix_B = "3;2;7,8,9,10,11,12;";       // 3x2 matrix

    std::string k = "5;3;0.00041624,-0.00041734,-0.000835,0.00083908,0.0008333,0.00084516,-0.00084918,-0.00040503,0.00040617,-0.00081487,0.0095941,-0.0095774,0.0096154,-0.0095994,0.019302;";

    // --- Test Matrix Multiplication ---
    std::cout << "\n--- Testing Matrix Multiplication ---" << std::endl;

    Matrix matrix_a = Matrix::from_string(k); // 2x3
    Matrix matrix_b(3,1,{0.6, 0.1, 0.1});
    
    if (!matrix_a.is_valid()) {
        std::cout << "matrix A is not valid!\n";
        matrix_a.print();
        
        return 0;
    } 

    matrix_a.print();
    
    auto res = matrix_a.scale(-1.0).multiply(matrix_b);
    
    std::cout << "\n";
    
    res.print();

    return 0;
}