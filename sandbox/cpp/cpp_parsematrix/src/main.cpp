#include <iostream>
#include <vector>
#include <string>
// #include "Matrix.h"
#include "helper.h"

// --- Main function for demonstration ---
int main() {

    // --- Test Cases for String Parsing and Matrix Creation ---
    // std::string str_matrix_A = "2;3;1,2,3,4,5,6;";          // 2x3 matrix
    std::string str_matrix_A = "2;4;1,2,3,4,5,6;";          // 2x3 matrix
    std::string str_matrix_B = "3;2;7,8,9,10,11,12;";       // 3x2 matrix

    // --- format "m;n;gain_k[];time_us[];modes[];"
    std::string test_1 = "1;2;0.00041624,0.0154;40,25,16;1,5,7,8,4,1,6,85,8,115,3;";
    // std::string k = "5;3;0.00041624,-0.00041734,-0.000835,0.00083908,0.0008333,0.00084516,-0.00084918,-0.00040503,0.00040617,-0.00081487,0.0095941,-0.0095774,0.0096154,-0.0095994,0.019302;";

    // --- Test Matrix Multiplication ---
    std::cout << "\n--- Testing Matrix Multiplication ---" << std::endl;

    
    int m,n;
    std::vector<double> gain_k;
    std::vector<uint64_t> times;
    std::vector<uint64_t> modes;
    ERROR_CODE err;

    err = parse_message_data(test_1, m, n, gain_k, times, modes);
    
    if (err != ERROR_CODE::OK) {
        print_error_code(err);
        return 0;
    }
    
    std::cout << "gain_k:\n";
    for (auto n : gain_k) {
        std::cout << n << "\n";
    }

    std::cout << "times[]:\n";
    for (auto n : times) {
        std::cout << n << "\n";
    }

    std::cout << "modes[]:\n";
    for (auto n : modes) {
        std::cout << n << "\n";
    }
    
    
    






















    // Matrix matrix_a = Matrix::from_string(k); // 2x3
    // Matrix matrix_b(3,1,{0.6, 0.1, 0.1});
    
    // if (!matrix_a.is_valid()) {
    //     std::cout << "matrix A is not valid!\n";
    //     matrix_a.print();
        
    //     return 0;
    // } 

    // matrix_a.print();
    
    // auto res = matrix_a.scale(-1.0).multiply(matrix_b);
    
    // std::cout << "\n";
    
    // res.print();

    // 133 us
    // 108 us
    return 0;
}