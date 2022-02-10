//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: _coder_fun_invert_matrix_up2_5_api.h
//
// MATLAB Coder version            : 5.3
// C/C++ source code generated on  : 09-Feb-2022 23:17:25
//

#ifndef _CODER_FUN_INVERT_MATRIX_UP2_5_API_H
#define _CODER_FUN_INVERT_MATRIX_UP2_5_API_H

// Include Files
#include "emlrt.h"
#include "tmwtypes.h"
#include <algorithm>
#include <cstring>

// Variable Declarations
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

// Function Declarations
void fun_invert_matrix_up2_5(real_T A_data[], int32_T A_size[2],
                             real_T Ai_data[], int32_T Ai_size[2]);

void fun_invert_matrix_up2_5_api(const mxArray *prhs, const mxArray **plhs);

void fun_invert_matrix_up2_5_atexit();

void fun_invert_matrix_up2_5_initialize();

void fun_invert_matrix_up2_5_terminate();

void fun_invert_matrix_up2_5_xil_shutdown();

void fun_invert_matrix_up2_5_xil_terminate();

#endif
//
// File trailer for _coder_fun_invert_matrix_up2_5_api.h
//
// [EOF]
//
