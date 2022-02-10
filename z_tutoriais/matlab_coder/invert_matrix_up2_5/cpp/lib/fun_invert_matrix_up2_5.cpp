//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: fun_invert_matrix_up2_5.cpp
//
// MATLAB Coder version            : 5.3
// C/C++ source code generated on  : 09-Feb-2022 23:17:25
//

// Include Files
#include "fun_invert_matrix_up2_5.h"
#include <algorithm>
#include <cmath>
#include <cstring>

// Function Definitions
//
// fun_invert_matrix_up2_5 - funcao para inverter a matriz 3x3
//
//  Prototype   : r = fun_invert_matrix_up2_5(a, b)
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
//  2022-02-09: Daniel Vieira - versao inicial
//
//
// Arguments    : const double A_data[]
//                const int A_size[2]
//                double Ai_data[]
//                int Ai_size[2]
// Return Type  : void
//
void fun_invert_matrix_up2_5(const double A_data[], const int A_size[2],
                             double Ai_data[], int Ai_size[2])
{
  double x_data[25];
  int ipiv_data[5];
  int p_data[5];
  if ((A_size[0] == 0) || (A_size[1] == 0)) {
    int b_n;
    Ai_size[0] = A_size[0];
    Ai_size[1] = A_size[1];
    b_n = A_size[0] * A_size[1];
    if (0 <= b_n - 1) {
      std::copy(&A_data[0], &A_data[b_n], &Ai_data[0]);
    }
  } else {
    int b_n;
    int i;
    int ipiv_size_idx_1;
    int j;
    int jp1j;
    int k;
    int ldap1;
    int n;
    int temp_tmp;
    int u1;
    int x_size_idx_0;
    int yk;
    n = A_size[0];
    Ai_size[0] = A_size[0];
    Ai_size[1] = A_size[1];
    b_n = A_size[0] * A_size[1];
    if (0 <= b_n - 1) {
      std::memset(&Ai_data[0], 0, b_n * sizeof(double));
    }
    x_size_idx_0 = A_size[0];
    if (0 <= b_n - 1) {
      std::copy(&A_data[0], &A_data[b_n], &x_data[0]);
    }
    b_n = A_size[0];
    ipiv_size_idx_1 = A_size[0];
    ipiv_data[0] = 1;
    yk = 1;
    for (k = 2; k <= b_n; k++) {
      yk++;
      ipiv_data[k - 1] = yk;
    }
    ldap1 = A_size[0];
    b_n = A_size[0] - 1;
    u1 = A_size[0];
    if (b_n <= u1) {
      u1 = b_n;
    }
    for (j = 0; j < u1; j++) {
      double smax;
      int b;
      int jj;
      int mmj_tmp;
      mmj_tmp = n - j;
      b = j * (n + 1);
      jj = j * (ldap1 + 1);
      jp1j = b + 2;
      if (mmj_tmp < 1) {
        b_n = -1;
      } else {
        b_n = 0;
        if (mmj_tmp > 1) {
          smax = std::abs(x_data[jj]);
          for (k = 2; k <= mmj_tmp; k++) {
            double s;
            s = std::abs(x_data[(b + k) - 1]);
            if (s > smax) {
              b_n = k - 1;
              smax = s;
            }
          }
        }
      }
      if (x_data[jj + b_n] != 0.0) {
        if (b_n != 0) {
          yk = j + b_n;
          ipiv_data[j] = yk + 1;
          for (k = 0; k < n; k++) {
            b_n = k * n;
            temp_tmp = j + b_n;
            smax = x_data[temp_tmp];
            b_n += yk;
            x_data[temp_tmp] = x_data[b_n];
            x_data[b_n] = smax;
          }
        }
        i = jj + mmj_tmp;
        for (temp_tmp = jp1j; temp_tmp <= i; temp_tmp++) {
          x_data[temp_tmp - 1] /= x_data[jj];
        }
      }
      b_n = b + n;
      yk = jj + ldap1;
      for (temp_tmp = 0; temp_tmp <= mmj_tmp - 2; temp_tmp++) {
        smax = x_data[b_n + temp_tmp * n];
        if (smax != 0.0) {
          i = yk + 2;
          jp1j = mmj_tmp + yk;
          for (b = i; b <= jp1j; b++) {
            x_data[b - 1] += x_data[((jj + b) - yk) - 1] * -smax;
          }
        }
        yk += n;
      }
    }
    b_n = A_size[0];
    p_data[0] = 1;
    yk = 1;
    for (k = 2; k <= b_n; k++) {
      yk++;
      p_data[k - 1] = yk;
    }
    for (k = 0; k < ipiv_size_idx_1; k++) {
      i = ipiv_data[k];
      if (i > k + 1) {
        b_n = p_data[i - 1];
        p_data[i - 1] = p_data[k];
        p_data[k] = b_n;
      }
    }
    for (k = 0; k < n; k++) {
      i = p_data[k];
      b_n = Ai_size[0] * (i - 1);
      Ai_data[k + b_n] = 1.0;
      for (j = k + 1; j <= n; j++) {
        if (Ai_data[(j + b_n) - 1] != 0.0) {
          jp1j = j + 1;
          for (temp_tmp = jp1j; temp_tmp <= n; temp_tmp++) {
            yk = (temp_tmp + Ai_size[0] * (i - 1)) - 1;
            Ai_data[yk] -= Ai_data[(j + Ai_size[0] * (i - 1)) - 1] *
                           x_data[(temp_tmp + x_size_idx_0 * (j - 1)) - 1];
          }
        }
      }
    }
    for (j = 0; j < n; j++) {
      b_n = n * j - 1;
      for (k = n; k >= 1; k--) {
        yk = n * (k - 1) - 1;
        i = k + b_n;
        if (Ai_data[i] != 0.0) {
          Ai_data[i] /= x_data[k + yk];
          for (temp_tmp = 0; temp_tmp <= k - 2; temp_tmp++) {
            jp1j = (temp_tmp + b_n) + 1;
            Ai_data[jp1j] -= Ai_data[i] * x_data[(temp_tmp + yk) + 1];
          }
        }
      }
    }
  }
}

//
// Arguments    : void
// Return Type  : void
//
void fun_invert_matrix_up2_5_initialize()
{
}

//
// Arguments    : void
// Return Type  : void
//
void fun_invert_matrix_up2_5_terminate()
{
  // (no terminate code required)
}

//
// File trailer for fun_invert_matrix_up2_5.cpp
//
// [EOF]
//
