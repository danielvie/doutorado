//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: _coder_fun_soma_api.h
//
// MATLAB Coder version            : 5.3
// C/C++ source code generated on  : 08-Feb-2022 01:44:01
//

#ifndef _CODER_FUN_SOMA_API_H
#define _CODER_FUN_SOMA_API_H

// Include Files
#include "emlrt.h"
#include "tmwtypes.h"
#include <algorithm>
#include <cstring>

// Variable Declarations
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

// Function Declarations
int32_T fun_soma(int32_T a, int32_T b);

void fun_soma_api(const mxArray *const prhs[2], const mxArray **plhs);

void fun_soma_atexit();

void fun_soma_initialize();

void fun_soma_terminate();

void fun_soma_xil_shutdown();

void fun_soma_xil_terminate();

#endif
//
// File trailer for _coder_fun_soma_api.h
//
// [EOF]
//
