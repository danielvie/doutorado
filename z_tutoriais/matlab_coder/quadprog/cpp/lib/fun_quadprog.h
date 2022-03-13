//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: fun_quadprog.h
//
// MATLAB Coder version            : 5.3
// C/C++ source code generated on  : 11-Feb-2022 01:47:26
//

#ifndef FUN_QUADPROG_H
#define FUN_QUADPROG_H

// Include Files
#include "rtwtypes.h"
#include <cstddef>
#include <cstdlib>

// Function Declarations
extern void fun_quadprog(const double H[9], const double f[3],
                         const double A[3], double b, const double lb[3],
                         const double x0[3], double x[3], double *fval,
                         double *exitflag);

extern void fun_quadprog_initialize();

extern void fun_quadprog_terminate();

#endif
//
// File trailer for fun_quadprog.h
//
// [EOF]
//
