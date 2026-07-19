//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: fun_soma.cpp
//
// MATLAB Coder version            : 5.3
// C/C++ source code generated on  : 08-Feb-2022 01:44:01
//

// Include Files
#include "fun_soma.h"

// Function Definitions
//
// fun_soma - funcao para somar `a` e `b`
//
//  Prototype   : r = fun_soma(a, b)
//  Description : soma `a` e `b`
//
//  In          : a - primeiro valor
//                b - segundo valor
//
//  Out         : r - resultado da soma
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
// Arguments    : int a
//                int b
// Return Type  : int
//
int fun_soma(int a, int b)
{
  int r;
  if ((a < 0) && (b < MIN_int32_T - a)) {
    r = MIN_int32_T;
  } else if ((a > 0) && (b > MAX_int32_T - a)) {
    r = MAX_int32_T;
  } else {
    r = a + b;
  }
  return r;
}

//
// Arguments    : void
// Return Type  : void
//
void fun_soma_initialize()
{
}

//
// Arguments    : void
// Return Type  : void
//
void fun_soma_terminate()
{
  // (no terminate code required)
}

//
// File trailer for fun_soma.cpp
//
// [EOF]
//
