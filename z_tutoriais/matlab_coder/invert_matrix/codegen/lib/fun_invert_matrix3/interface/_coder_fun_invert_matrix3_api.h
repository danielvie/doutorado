//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: _coder_fun_invert_matrix3_api.h
//
// MATLAB Coder version            : 5.3
// C/C++ source code generated on  : 08-Feb-2022 01:50:40
//

#ifndef _CODER_FUN_INVERT_MATRIX3_API_H
#define _CODER_FUN_INVERT_MATRIX3_API_H

// Include Files
#include "emlrt.h"
#include "tmwtypes.h"
#include <algorithm>
#include <cstring>

// Variable Declarations
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

// Function Declarations
void fun_invert_matrix3(real_T A[9], real_T Ai[9]);

void fun_invert_matrix3_api(const mxArray *prhs, const mxArray **plhs);

void fun_invert_matrix3_atexit();

void fun_invert_matrix3_initialize();

void fun_invert_matrix3_terminate();

void fun_invert_matrix3_xil_shutdown();

void fun_invert_matrix3_xil_terminate();

#endif
//
// File trailer for _coder_fun_invert_matrix3_api.h
//
// [EOF]
//
