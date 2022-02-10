//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: fun_invert_matrix3.cpp
//
// MATLAB Coder version            : 5.3
// C/C++ source code generated on  : 08-Feb-2022 01:50:40
//

// Include Files
#include "fun_invert_matrix3.h"
#include <algorithm>
#include <cmath>

// Function Definitions
//
// fun_invert_matrix - funcao para inverter a matriz 3x3
//
//  Prototype   : r = fun_invert_matrix(a, b)
//  Description : sfuncao para inverter a matriz
//
//  In          : A - matrix a ser invertida
//
//  Out         : Ai - inversa da matriz
//
//  Pre. Cond   : ----
//
//  Post. Cond. : ----
//
//  Notes       : ----
//
//  --------------------------------------------------------------------------------
//
//            MATLAB Function
//
//  --------------------------------------------------------------------------------
//
//  Author : Daniel Vieira
//
//  History
//  yyyy-mm-dd: <author> - <change description>
//
//  2022-02-08: Daniel Vieira - versao inicial
//
//
// Arguments    : const double A[9]
//                double Ai[9]
// Return Type  : void
//
void fun_invert_matrix3(const double A[9], double Ai[9])
{
  double x[9];
  double absx11;
  double absx21;
  double absx31;
  int p1;
  int p2;
  int p3;
  std::copy(&A[0], &A[9], &x[0]);
  p1 = 0;
  p2 = 3;
  p3 = 6;
  absx11 = std::abs(A[0]);
  absx21 = std::abs(A[1]);
  absx31 = std::abs(A[2]);
  if ((absx21 > absx11) && (absx21 > absx31)) {
    p1 = 3;
    p2 = 0;
    x[0] = A[1];
    x[1] = A[0];
    x[3] = A[4];
    x[4] = A[3];
    x[6] = A[7];
    x[7] = A[6];
  } else if (absx31 > absx11) {
    p1 = 6;
    p3 = 0;
    x[0] = A[2];
    x[2] = A[0];
    x[3] = A[5];
    x[5] = A[3];
    x[6] = A[8];
    x[8] = A[6];
  }
  x[1] /= x[0];
  x[2] /= x[0];
  x[4] -= x[1] * x[3];
  x[5] -= x[2] * x[3];
  x[7] -= x[1] * x[6];
  x[8] -= x[2] * x[6];
  if (std::abs(x[5]) > std::abs(x[4])) {
    int itmp;
    itmp = p2;
    p2 = p3;
    p3 = itmp;
    absx11 = x[1];
    x[1] = x[2];
    x[2] = absx11;
    absx11 = x[4];
    x[4] = x[5];
    x[5] = absx11;
    absx11 = x[7];
    x[7] = x[8];
    x[8] = absx11;
  }
  x[5] /= x[4];
  x[8] -= x[5] * x[7];
  absx11 = (x[1] * x[5] - x[2]) / x[8];
  absx21 = -(x[1] + x[7] * absx11) / x[4];
  Ai[p1] = ((1.0 - x[3] * absx21) - x[6] * absx11) / x[0];
  Ai[p1 + 1] = absx21;
  Ai[p1 + 2] = absx11;
  absx11 = -x[5] / x[8];
  absx21 = (1.0 - x[7] * absx11) / x[4];
  Ai[p2] = -(x[3] * absx21 + x[6] * absx11) / x[0];
  Ai[p2 + 1] = absx21;
  Ai[p2 + 2] = absx11;
  absx11 = 1.0 / x[8];
  absx21 = -x[7] * absx11 / x[4];
  Ai[p3] = -(x[3] * absx21 + x[6] * absx11) / x[0];
  Ai[p3 + 1] = absx21;
  Ai[p3 + 2] = absx11;
}

//
// Arguments    : void
// Return Type  : void
//
void fun_invert_matrix3_initialize()
{
}

//
// Arguments    : void
// Return Type  : void
//
void fun_invert_matrix3_terminate()
{
  // (no terminate code required)
}

//
// File trailer for fun_invert_matrix3.cpp
//
// [EOF]
//
