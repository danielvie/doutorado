//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: fun_quadprog.cpp
//
// MATLAB Coder version            : 5.3
// C/C++ source code generated on  : 11-Feb-2022 01:47:26
//

// Include Files
#include "fun_quadprog.h"
#include "rt_nonfinite.h"
#include <algorithm>
#include <cmath>
#include <cstring>

// Type Definitions
struct struct_T {
  double xstar[4];
  double fstar;
  double firstorderopt;
  double lambda[5];
  int state;
  double maxConstr;
  int iterations;
  double searchDir[4];
};

struct b_struct_T {
  double grad[4];
  double Hx[3];
  boolean_T hasLinear;
  int nvar;
  int maxVar;
  double beta;
  double rho;
  int objtype;
  int prev_objtype;
  int prev_nvar;
  boolean_T prev_hasLinear;
  double gammaScalar;
};

struct c_struct_T {
  double FMat[16];
  int ldm;
  int ndims;
  int info;
  double scaleFactor;
  boolean_T ConvexCheck;
  double regTol_;
  double workspace_[192];
  double workspace2_[192];
};

struct d_struct_T {
  double workspace_double[20];
  int workspace_int[5];
  int workspace_sort[5];
};

struct e_struct_T {
  int ldq;
  double QR[20];
  double Q[16];
  int jpvt[5];
  int mrows;
  int ncols;
  double tau[4];
  int minRowCol;
  boolean_T usedPivoting;
};

struct f_struct_T {
  int mConstr;
  int mConstrOrig;
  int mConstrMax;
  int nVar;
  int nVarOrig;
  int nVarMax;
  int ldA;
  double Aineq[4];
  double bineq;
  double lb[4];
  double ub[4];
  int indexLB[4];
  int indexUB[4];
  int indexFixed[4];
  int mEqRemoved;
  double ATwset[20];
  double bwset[5];
  int nActiveConstr;
  double maxConstrWorkspace[5];
  int sizes[5];
  int sizesNormal[5];
  int sizesPhaseOne[5];
  int sizesRegularized[5];
  int sizesRegPhaseOne[5];
  int isActiveIdx[6];
  int isActiveIdxNormal[6];
  int isActiveIdxPhaseOne[6];
  int isActiveIdxRegularized[6];
  int isActiveIdxRegPhaseOne[6];
  boolean_T isActiveConstr[5];
  int Wid[5];
  int Wlocalidx[5];
  int nWConstr[5];
  int probType;
  double SLACK0;
};

struct g_struct_T {
  double InitDamping;
  char FiniteDifferenceType[7];
  boolean_T SpecifyObjectiveGradient;
  boolean_T ScaleProblem;
  boolean_T SpecifyConstraintGradient;
  boolean_T NonFiniteSupport;
  boolean_T IterDisplaySQP;
  double FiniteDifferenceStepSize;
  double MaxFunctionEvaluations;
  boolean_T IterDisplayQP;
  double PricingTolerance;
  char Algorithm[10];
  double ObjectiveLimit;
  double ConstraintTolerance;
  double OptimalityTolerance;
  double StepTolerance;
  double MaxIterations;
  double FunctionTolerance;
  char SolverName[8];
  boolean_T CheckGradients;
  char Diagnostics[3];
  double DiffMaxChange;
  double DiffMinChange;
  char Display[5];
  char FunValCheck[3];
  boolean_T UseParallel;
  char LinearSolver[4];
  char SubproblemAlgorithm[2];
};

// Function Declarations
namespace coder {
namespace internal {
namespace blas {
static double xnrm2(int n, const double x[4]);

static double xnrm2(int n, const double x[20], int ix0);

static void xrotg(double *a, double *b, double *c, double *s);

} // namespace blas
namespace reflapack {
static void qrf(double A[20], int m, int n, int nfxd, double tau[4]);

static void xzlarf(int m, int n, int iv0, double tau, double C[20], int ic0,
                   double work[5]);

static double xzlarfg(int n, double *alpha1, double x[20], int ix0);

} // namespace reflapack
} // namespace internal
namespace optim {
namespace coder {
namespace DynamicRegCholManager {
static void fullColLDL2_(c_struct_T *obj, int NColsRemain, double REG_PRIMAL);

}
namespace QRManager {
static void computeQ_(e_struct_T *obj, int nrows);

static void deleteColMoveEnd(e_struct_T *obj, int idx);

static void factorQR(e_struct_T *obj, const double A[20], int mrows, int ncols);

static void factorQRE(e_struct_T *obj, int mrows, int ncols);

} // namespace QRManager
namespace qpactiveset {
namespace Objective {
static void b_linearForm_(boolean_T obj_hasLinear, int obj_nvar,
                          double workspace[4], const double H[9],
                          const double f[3], const double x[4]);

static double computeFval(const b_struct_T *obj, double workspace[20],
                          const double H[9], const double f[3],
                          const double x[4]);

static double computeFval_ReuseHx(const b_struct_T *obj, double workspace[20],
                                  const double f[3], const double x[4]);

static void computeGrad_StoreHx(b_struct_T *obj, const double H[9],
                                const double f[3], const double x[4]);

static void linearForm_(boolean_T obj_hasLinear, int obj_nvar,
                        double workspace[20], const double H[9],
                        const double f[3], const double x[4]);

} // namespace Objective
namespace WorkingSet {
static void addBoundToActiveSetMatrix_(f_struct_T *obj, int TYPE,
                                       int idx_local);

static double maxConstraintViolation(f_struct_T *obj, const double x[4]);

static void setProblemType(f_struct_T *obj, int PROBLEM_TYPE);

} // namespace WorkingSet
static void compute_deltax(const double H[9], struct_T *solution,
                           d_struct_T *memspace, const e_struct_T *qrmanager,
                           c_struct_T *cholmanager,
                           const b_struct_T *objective);

static void compute_lambda(double workspace[20], struct_T *solution,
                           const b_struct_T *objective,
                           const e_struct_T *qrmanager);

static void driver(const double H[9], const double f[3], struct_T *solution,
                   d_struct_T *memspace, f_struct_T *workingset,
                   c_struct_T *cholmanager, int runTimeOptions_MaxIterations,
                   double runTimeOptions_ConstrRelTolFactor,
                   double runTimeOptions_ProbRelTolFactor,
                   e_struct_T *qrmanager, b_struct_T *objective);

static void feasibleratiotest(
    const double solution_xstar[4], const double solution_searchDir[4],
    double workspace[20], int workingset_nVar, const double workingset_Aineq[4],
    double workingset_bineq, const double workingset_lb[4],
    const int workingset_indexLB[4], const int workingset_sizes[5],
    const int workingset_isActiveIdx[6],
    const boolean_T workingset_isActiveConstr[5],
    const int workingset_nWConstr[5], boolean_T isPhaseOne, double *alpha,
    boolean_T *newBlocking, int *constrType, int *constrIdx);

namespace initialize {
static void PresolveWorkingSet(struct_T *solution, d_struct_T *memspace,
                               f_struct_T *workingset, e_struct_T *qrmanager);

static void RemoveDependentIneq_(f_struct_T *workingset, e_struct_T *qrmanager,
                                 d_struct_T *memspace, double tolfactor);

static boolean_T feasibleX0ForWorkingSet(double workspace[20],
                                         double xCurrent[4],
                                         f_struct_T *workingset,
                                         e_struct_T *qrmanager);

} // namespace initialize
static void iterate(const double H[9], const double f[3], struct_T *solution,
                    d_struct_T *memspace, f_struct_T *workingset,
                    e_struct_T *qrmanager, c_struct_T *cholmanager,
                    b_struct_T *objective, double options_ObjectiveLimit,
                    double options_StepTolerance,
                    int runTimeOptions_MaxIterations,
                    double runTimeOptions_ConstrRelTolFactor,
                    double runTimeOptions_ProbRelTolFactor,
                    boolean_T runTimeOptions_RemainFeasible);

namespace parseoutput {
static void
computeFirstOrderOpt(struct_T *solution, const b_struct_T *objective,
                     int workingset_nVar, const double workingset_ATwset[20],
                     int workingset_nActiveConstr, double workspace[20]);

}
static void
ratiotest(const double solution_xstar[4], const double solution_searchDir[4],
          double workspace[20], int workingset_nVar,
          const double workingset_Aineq[4], double workingset_bineq,
          const double workingset_lb[4], const int workingset_indexLB[4],
          const int workingset_sizes[5], const int workingset_isActiveIdx[6],
          const boolean_T workingset_isActiveConstr[5],
          const int workingset_nWConstr[5], double *toldelta, double *alpha,
          boolean_T *newBlocking, int *constrType, int *constrIdx);

} // namespace qpactiveset
namespace utils {
static void countsort(int x[5], int xLen, int workspace[5], int xMin, int xMax);

}
} // namespace coder
} // namespace optim
} // namespace coder
static double rt_hypotd_snf(double u0, double u1);

// Function Definitions
//
// Arguments    : int n
//                const double x[4]
// Return Type  : double
//
namespace coder {
namespace internal {
namespace blas {
static double xnrm2(int n, const double x[4])
{
  double y;
  y = 0.0;
  if (n >= 1) {
    if (n == 1) {
      y = std::abs(x[0]);
    } else {
      double scale;
      scale = 3.3121686421112381E-170;
      for (int k{0}; k < n; k++) {
        double absxk;
        absxk = std::abs(x[k]);
        if (absxk > scale) {
          double t;
          t = scale / absxk;
          y = y * t * t + 1.0;
          scale = absxk;
        } else {
          double t;
          t = absxk / scale;
          y += t * t;
        }
      }
      y = scale * std::sqrt(y);
    }
  }
  return y;
}

//
// Arguments    : int n
//                const double x[20]
//                int ix0
// Return Type  : double
//
static double xnrm2(int n, const double x[20], int ix0)
{
  double y;
  y = 0.0;
  if (n >= 1) {
    if (n == 1) {
      y = std::abs(x[ix0 - 1]);
    } else {
      double scale;
      int kend;
      scale = 3.3121686421112381E-170;
      kend = (ix0 + n) - 1;
      for (int k{ix0}; k <= kend; k++) {
        double absxk;
        absxk = std::abs(x[k - 1]);
        if (absxk > scale) {
          double t;
          t = scale / absxk;
          y = y * t * t + 1.0;
          scale = absxk;
        } else {
          double t;
          t = absxk / scale;
          y += t * t;
        }
      }
      y = scale * std::sqrt(y);
    }
  }
  return y;
}

//
// Arguments    : double *a
//                double *b
//                double *c
//                double *s
// Return Type  : void
//
static void xrotg(double *a, double *b, double *c, double *s)
{
  double absa;
  double absb;
  double roe;
  double scale;
  roe = *b;
  absa = std::abs(*a);
  absb = std::abs(*b);
  if (absa > absb) {
    roe = *a;
  }
  scale = absa + absb;
  if (scale == 0.0) {
    *s = 0.0;
    *c = 1.0;
    *a = 0.0;
    *b = 0.0;
  } else {
    double ads;
    double bds;
    ads = absa / scale;
    bds = absb / scale;
    scale *= std::sqrt(ads * ads + bds * bds);
    if (roe < 0.0) {
      scale = -scale;
    }
    *c = *a / scale;
    *s = *b / scale;
    if (absa > absb) {
      *b = *s;
    } else if (*c != 0.0) {
      *b = 1.0 / *c;
    } else {
      *b = 1.0;
    }
    *a = scale;
  }
}

//
// Arguments    : double A[20]
//                int m
//                int n
//                int nfxd
//                double tau[4]
// Return Type  : void
//
} // namespace blas
namespace reflapack {
static void qrf(double A[20], int m, int n, int nfxd, double tau[4])
{
  double work[5];
  double atmp;
  int i;
  tau[0] = 0.0;
  tau[1] = 0.0;
  tau[2] = 0.0;
  tau[3] = 0.0;
  for (i = 0; i < 5; i++) {
    work[i] = 0.0;
  }
  for (i = 0; i < nfxd; i++) {
    double d;
    int ii;
    int mmi;
    ii = (i << 2) + i;
    mmi = m - i;
    if (i + 1 < m) {
      atmp = A[ii];
      d = xzlarfg(mmi, &atmp, A, ii + 2);
      tau[i] = d;
      A[ii] = atmp;
    } else {
      d = 0.0;
      tau[i] = 0.0;
    }
    if (i + 1 < n) {
      atmp = A[ii];
      A[ii] = 1.0;
      xzlarf(mmi, (n - i) - 1, ii + 1, d, A, ii + 5, work);
      A[ii] = atmp;
    }
  }
}

//
// Arguments    : int m
//                int n
//                int iv0
//                double tau
//                double C[20]
//                int ic0
//                double work[5]
// Return Type  : void
//
static void xzlarf(int m, int n, int iv0, double tau, double C[20], int ic0,
                   double work[5])
{
  int i;
  int ia;
  int lastc;
  int lastv;
  if (tau != 0.0) {
    boolean_T exitg2;
    lastv = m;
    i = iv0 + m;
    while ((lastv > 0) && (C[i - 2] == 0.0)) {
      lastv--;
      i--;
    }
    lastc = n - 1;
    exitg2 = false;
    while ((!exitg2) && (lastc + 1 > 0)) {
      int exitg1;
      i = ic0 + (lastc << 2);
      ia = i;
      do {
        exitg1 = 0;
        if (ia <= (i + lastv) - 1) {
          if (C[ia - 1] != 0.0) {
            exitg1 = 1;
          } else {
            ia++;
          }
        } else {
          lastc--;
          exitg1 = 2;
        }
      } while (exitg1 == 0);
      if (exitg1 == 1) {
        exitg2 = true;
      }
    }
  } else {
    lastv = 0;
    lastc = -1;
  }
  if (lastv > 0) {
    double c;
    int b_i;
    int iac;
    if (lastc + 1 != 0) {
      if (0 <= lastc) {
        std::memset(&work[0], 0, (lastc + 1) * sizeof(double));
      }
      b_i = ic0 + (lastc << 2);
      for (iac = ic0; iac <= b_i; iac += 4) {
        c = 0.0;
        i = (iac + lastv) - 1;
        for (ia = iac; ia <= i; ia++) {
          c += C[ia - 1] * C[((iv0 + ia) - iac) - 1];
        }
        i = (iac - ic0) >> 2;
        work[i] += c;
      }
    }
    if (!(-tau == 0.0)) {
      i = ic0;
      for (iac = 0; iac <= lastc; iac++) {
        if (work[iac] != 0.0) {
          c = work[iac] * -tau;
          b_i = lastv + i;
          for (ia = i; ia < b_i; ia++) {
            C[ia - 1] += C[((iv0 + ia) - i) - 1] * c;
          }
        }
        i += 4;
      }
    }
  }
}

//
// Arguments    : int n
//                double *alpha1
//                double x[20]
//                int ix0
// Return Type  : double
//
static double xzlarfg(int n, double *alpha1, double x[20], int ix0)
{
  double tau;
  tau = 0.0;
  if (n > 0) {
    double xnorm;
    xnorm = blas::xnrm2(n - 1, x, ix0);
    if (xnorm != 0.0) {
      double beta1;
      beta1 = rt_hypotd_snf(*alpha1, xnorm);
      if (*alpha1 >= 0.0) {
        beta1 = -beta1;
      }
      if (std::abs(beta1) < 1.0020841800044864E-292) {
        int i;
        int k;
        int knt;
        knt = -1;
        i = (ix0 + n) - 2;
        do {
          knt++;
          for (k = ix0; k <= i; k++) {
            x[k - 1] *= 9.9792015476736E+291;
          }
          beta1 *= 9.9792015476736E+291;
          *alpha1 *= 9.9792015476736E+291;
        } while (!(std::abs(beta1) >= 1.0020841800044864E-292));
        beta1 = rt_hypotd_snf(*alpha1, blas::xnrm2(n - 1, x, ix0));
        if (*alpha1 >= 0.0) {
          beta1 = -beta1;
        }
        tau = (beta1 - *alpha1) / beta1;
        xnorm = 1.0 / (*alpha1 - beta1);
        for (k = ix0; k <= i; k++) {
          x[k - 1] *= xnorm;
        }
        for (k = 0; k <= knt; k++) {
          beta1 *= 1.0020841800044864E-292;
        }
        *alpha1 = beta1;
      } else {
        int i;
        tau = (beta1 - *alpha1) / beta1;
        xnorm = 1.0 / (*alpha1 - beta1);
        i = (ix0 + n) - 2;
        for (int k{ix0}; k <= i; k++) {
          x[k - 1] *= xnorm;
        }
        *alpha1 = beta1;
      }
    }
  }
  return tau;
}

//
// Arguments    : c_struct_T *obj
//                int NColsRemain
//                double REG_PRIMAL
// Return Type  : void
//
} // namespace reflapack
} // namespace internal
namespace optim {
namespace coder {
namespace DynamicRegCholManager {
static void fullColLDL2_(c_struct_T *obj, int NColsRemain, double REG_PRIMAL)
{
  int jA;
  for (int k{0}; k < NColsRemain; k++) {
    double alpha1;
    int LD_diagOffset;
    int i;
    int subMatrixDim;
    LD_diagOffset = 5 * k;
    if (std::abs(obj->FMat[LD_diagOffset]) <= obj->regTol_) {
      obj->FMat[LD_diagOffset] += REG_PRIMAL;
    }
    alpha1 = -1.0 / obj->FMat[LD_diagOffset];
    subMatrixDim = (NColsRemain - k) - 2;
    for (jA = 0; jA <= subMatrixDim; jA++) {
      obj->workspace_[jA] = obj->FMat[(LD_diagOffset + jA) + 1];
    }
    if (!(alpha1 == 0.0)) {
      jA = LD_diagOffset;
      for (int j{0}; j <= subMatrixDim; j++) {
        if (obj->workspace_[j] != 0.0) {
          double temp;
          int i1;
          temp = obj->workspace_[j] * alpha1;
          i = jA + 6;
          i1 = subMatrixDim + jA;
          for (int ijA{i}; ijA <= i1 + 6; ijA++) {
            obj->FMat[ijA - 1] += obj->workspace_[(ijA - jA) - 6] * temp;
          }
        }
        jA += 4;
      }
    }
    for (jA = 0; jA <= subMatrixDim; jA++) {
      i = (LD_diagOffset + jA) + 1;
      obj->FMat[i] /= obj->FMat[LD_diagOffset];
    }
  }
  jA = 5 * (NColsRemain - 1);
  if (std::abs(obj->FMat[jA]) <= obj->regTol_) {
    obj->FMat[jA] += REG_PRIMAL;
  }
}

//
// Arguments    : e_struct_T *obj
//                int nrows
// Return Type  : void
//
} // namespace DynamicRegCholManager
namespace QRManager {
static void computeQ_(e_struct_T *obj, int nrows)
{
  double work[4];
  int i;
  int iQR0;
  int idx;
  int m;
  int n;
  i = obj->minRowCol;
  for (idx = 0; idx < i; idx++) {
    iQR0 = (idx << 2) + idx;
    n = obj->mrows - idx;
    if (0 <= n - 2) {
      std::copy(&obj->QR[iQR0 + 1], &obj->QR[iQR0 + ((n + iQR0) - iQR0)],
                &obj->Q[iQR0 + 1]);
    }
  }
  m = obj->mrows;
  n = obj->minRowCol;
  if (nrows >= 1) {
    int i1;
    int ia;
    int itau;
    i = nrows - 1;
    for (idx = n; idx <= i; idx++) {
      ia = idx << 2;
      i1 = m - 1;
      if (0 <= i1) {
        std::memset(&obj->Q[ia], 0, (((i1 + ia) - ia) + 1) * sizeof(double));
      }
      obj->Q[ia + idx] = 1.0;
    }
    itau = obj->minRowCol - 1;
    work[0] = 0.0;
    work[1] = 0.0;
    work[2] = 0.0;
    work[3] = 0.0;
    for (int b_i = obj->minRowCol; b_i >= 1; b_i--) {
      int iaii;
      iaii = b_i + ((b_i - 1) << 2);
      if (b_i < nrows) {
        int lastc;
        int lastv;
        obj->Q[iaii - 1] = 1.0;
        idx = iaii + 4;
        if (obj->tau[itau] != 0.0) {
          boolean_T exitg2;
          lastv = m - b_i;
          iQR0 = (iaii + m) - b_i;
          while ((lastv + 1 > 0) && (obj->Q[iQR0 - 1] == 0.0)) {
            lastv--;
            iQR0--;
          }
          lastc = (nrows - b_i) - 1;
          exitg2 = false;
          while ((!exitg2) && (lastc + 1 > 0)) {
            int exitg1;
            iQR0 = (iaii + (lastc << 2)) + 4;
            ia = iQR0;
            do {
              exitg1 = 0;
              if (ia <= iQR0 + lastv) {
                if (obj->Q[ia - 1] != 0.0) {
                  exitg1 = 1;
                } else {
                  ia++;
                }
              } else {
                lastc--;
                exitg1 = 2;
              }
            } while (exitg1 == 0);
            if (exitg1 == 1) {
              exitg2 = true;
            }
          }
        } else {
          lastv = -1;
          lastc = -1;
        }
        if (lastv + 1 > 0) {
          double c;
          if (lastc + 1 != 0) {
            if (0 <= lastc) {
              std::memset(&work[0], 0, (lastc + 1) * sizeof(double));
            }
            i = (iaii + (lastc << 2)) + 4;
            for (n = idx; n <= i; n += 4) {
              c = 0.0;
              i1 = n + lastv;
              for (ia = n; ia <= i1; ia++) {
                c += obj->Q[ia - 1] * obj->Q[((iaii + ia) - n) - 1];
              }
              iQR0 = ((n - iaii) - 4) >> 2;
              work[iQR0] += c;
            }
          }
          if (!(-obj->tau[itau] == 0.0)) {
            iQR0 = iaii;
            for (idx = 0; idx <= lastc; idx++) {
              c = work[idx];
              if (c != 0.0) {
                c *= -obj->tau[itau];
                i = iQR0 + 4;
                i1 = lastv + iQR0;
                for (n = i; n <= i1 + 4; n++) {
                  obj->Q[n - 1] += obj->Q[((iaii + n) - iQR0) - 5] * c;
                }
              }
              iQR0 += 4;
            }
          }
        }
      }
      if (b_i < m) {
        iQR0 = iaii + 1;
        i = (iaii + m) - b_i;
        for (n = iQR0; n <= i; n++) {
          obj->Q[n - 1] *= -obj->tau[itau];
        }
      }
      obj->Q[iaii - 1] = 1.0 - obj->tau[itau];
      for (idx = 0; idx <= b_i - 2; idx++) {
        obj->Q[(iaii - idx) - 2] = 0.0;
      }
      itau--;
    }
  }
}

//
// Arguments    : e_struct_T *obj
//                int idx
// Return Type  : void
//
static void deleteColMoveEnd(e_struct_T *obj, int idx)
{
  double c;
  double s;
  double temp_tmp;
  int i;
  if (obj->usedPivoting) {
    i = 1;
    while ((i <= obj->ncols) && (obj->jpvt[i - 1] != idx)) {
      i++;
    }
    idx = i;
  }
  if (idx >= obj->ncols) {
    obj->ncols--;
  } else {
    int b_i;
    int k;
    int u0;
    obj->jpvt[idx - 1] = obj->jpvt[obj->ncols - 1];
    b_i = obj->minRowCol;
    for (k = 0; k < b_i; k++) {
      obj->QR[k + ((idx - 1) << 2)] = obj->QR[k + ((obj->ncols - 1) << 2)];
    }
    obj->ncols--;
    u0 = obj->mrows;
    i = obj->ncols;
    if (u0 <= i) {
      i = u0;
    }
    obj->minRowCol = i;
    if (idx < obj->mrows) {
      double c_temp_tmp;
      int QRk0;
      int b_k;
      int b_temp_tmp;
      int endIdx;
      int n;
      u0 = obj->mrows - 1;
      endIdx = obj->ncols;
      if (u0 <= endIdx) {
        endIdx = u0;
      }
      k = endIdx;
      i = (idx - 1) << 2;
      while (k >= idx) {
        b_i = k + i;
        temp_tmp = obj->QR[b_i];
        internal::blas::xrotg(&obj->QR[(k + i) - 1], &temp_tmp, &c, &s);
        obj->QR[b_i] = temp_tmp;
        b_i = (k - 1) << 2;
        obj->QR[k + b_i] = 0.0;
        QRk0 = k + (idx << 2);
        n = obj->ncols - idx;
        if (n >= 1) {
          for (b_k = 0; b_k < n; b_k++) {
            b_temp_tmp = QRk0 + (b_k << 2);
            temp_tmp = obj->QR[b_temp_tmp];
            c_temp_tmp = obj->QR[b_temp_tmp - 1];
            obj->QR[b_temp_tmp] = c * temp_tmp - s * c_temp_tmp;
            obj->QR[b_temp_tmp - 1] = c * c_temp_tmp + s * temp_tmp;
          }
        }
        n = obj->mrows;
        if (obj->mrows >= 1) {
          for (b_k = 0; b_k < n; b_k++) {
            b_temp_tmp = b_i + b_k;
            temp_tmp = obj->Q[b_temp_tmp + 4];
            c_temp_tmp = obj->Q[b_temp_tmp];
            obj->Q[b_temp_tmp + 4] = c * temp_tmp - s * c_temp_tmp;
            obj->Q[b_temp_tmp] = c * c_temp_tmp + s * temp_tmp;
          }
        }
        k--;
      }
      b_i = idx + 1;
      for (k = b_i; k <= endIdx; k++) {
        u0 = (k - 1) << 2;
        i = k + u0;
        temp_tmp = obj->QR[i];
        internal::blas::xrotg(&obj->QR[(k + u0) - 1], &temp_tmp, &c, &s);
        obj->QR[i] = temp_tmp;
        QRk0 = k * 5;
        n = obj->ncols - k;
        if (n >= 1) {
          for (b_k = 0; b_k < n; b_k++) {
            b_temp_tmp = QRk0 + (b_k << 2);
            temp_tmp = obj->QR[b_temp_tmp];
            c_temp_tmp = obj->QR[b_temp_tmp - 1];
            obj->QR[b_temp_tmp] = c * temp_tmp - s * c_temp_tmp;
            obj->QR[b_temp_tmp - 1] = c * c_temp_tmp + s * temp_tmp;
          }
        }
        n = obj->mrows;
        if (obj->mrows >= 1) {
          for (b_k = 0; b_k < n; b_k++) {
            b_temp_tmp = u0 + b_k;
            temp_tmp = obj->Q[b_temp_tmp + 4];
            c_temp_tmp = obj->Q[b_temp_tmp];
            obj->Q[b_temp_tmp + 4] = c * temp_tmp - s * c_temp_tmp;
            obj->Q[b_temp_tmp] = c * c_temp_tmp + s * temp_tmp;
          }
        }
      }
    }
  }
}

//
// Arguments    : e_struct_T *obj
//                const double A[20]
//                int mrows
//                int ncols
// Return Type  : void
//
static void factorQR(e_struct_T *obj, const double A[20], int mrows, int ncols)
{
  int idx;
  int ix0_tmp;
  boolean_T guard1{false};
  ix0_tmp = mrows * ncols;
  guard1 = false;
  if (ix0_tmp > 0) {
    for (idx = 0; idx < ncols; idx++) {
      ix0_tmp = idx << 2;
      if (0 <= mrows - 1) {
        std::copy(&A[ix0_tmp], &A[ix0_tmp + mrows], &obj->QR[ix0_tmp]);
      }
    }
    guard1 = true;
  } else if (ix0_tmp == 0) {
    obj->mrows = mrows;
    obj->ncols = ncols;
    obj->minRowCol = 0;
  } else {
    guard1 = true;
  }
  if (guard1) {
    obj->usedPivoting = false;
    obj->mrows = mrows;
    obj->ncols = ncols;
    for (idx = 0; idx < ncols; idx++) {
      obj->jpvt[idx] = idx + 1;
    }
    if (mrows <= ncols) {
      ix0_tmp = mrows;
    } else {
      ix0_tmp = ncols;
    }
    obj->minRowCol = ix0_tmp;
    obj->tau[0] = 0.0;
    obj->tau[1] = 0.0;
    obj->tau[2] = 0.0;
    obj->tau[3] = 0.0;
    if (ix0_tmp >= 1) {
      internal::reflapack::qrf(obj->QR, mrows, ncols, ix0_tmp, obj->tau);
    }
  }
}

//
// Arguments    : e_struct_T *obj
//                int mrows
//                int ncols
// Return Type  : void
//
static void factorQRE(e_struct_T *obj, int mrows, int ncols)
{
  double vn1[5];
  double vn2[5];
  double work[5];
  double temp;
  if (mrows * ncols == 0) {
    obj->mrows = mrows;
    obj->ncols = ncols;
    obj->minRowCol = 0;
  } else {
    int i;
    obj->usedPivoting = true;
    obj->mrows = mrows;
    obj->ncols = ncols;
    if (mrows <= ncols) {
      i = mrows;
    } else {
      i = ncols;
    }
    obj->minRowCol = i;
    obj->tau[0] = 0.0;
    obj->tau[1] = 0.0;
    obj->tau[2] = 0.0;
    obj->tau[3] = 0.0;
    if (i < 1) {
      for (int pvt{0}; pvt < ncols; pvt++) {
        obj->jpvt[pvt] = pvt + 1;
      }
    } else {
      int i1;
      int ix;
      int iy;
      int k;
      int nfxd;
      int pvt;
      int temp_tmp;
      nfxd = 0;
      for (pvt = 0; pvt < ncols; pvt++) {
        if (obj->jpvt[pvt] != 0) {
          nfxd++;
          if (pvt + 1 != nfxd) {
            ix = pvt << 2;
            iy = (nfxd - 1) << 2;
            for (k = 0; k < mrows; k++) {
              temp_tmp = ix + k;
              temp = obj->QR[temp_tmp];
              i1 = iy + k;
              obj->QR[temp_tmp] = obj->QR[i1];
              obj->QR[i1] = temp;
            }
            obj->jpvt[pvt] = obj->jpvt[nfxd - 1];
            obj->jpvt[nfxd - 1] = pvt + 1;
          } else {
            obj->jpvt[pvt] = pvt + 1;
          }
        } else {
          obj->jpvt[pvt] = pvt + 1;
        }
      }
      if (nfxd > i) {
        nfxd = i;
      }
      internal::reflapack::qrf(obj->QR, mrows, ncols, nfxd, obj->tau);
      if (nfxd < i) {
        int b_i;
        for (b_i = 0; b_i < 5; b_i++) {
          work[b_i] = 0.0;
          vn1[b_i] = 0.0;
          vn2[b_i] = 0.0;
        }
        i1 = nfxd + 1;
        for (pvt = i1; pvt <= ncols; pvt++) {
          temp = internal::blas::xnrm2(mrows - nfxd, obj->QR,
                                       (nfxd + ((pvt - 1) << 2)) + 1);
          vn1[pvt - 1] = temp;
          vn2[pvt - 1] = temp;
        }
        for (b_i = i1; b_i <= i; b_i++) {
          double s;
          int ii;
          int ip1;
          int mmi;
          int nmi;
          ip1 = b_i + 1;
          nfxd = (b_i - 1) << 2;
          ii = (nfxd + b_i) - 1;
          nmi = (ncols - b_i) + 1;
          mmi = mrows - b_i;
          if (nmi < 1) {
            iy = -2;
          } else {
            iy = -1;
            if (nmi > 1) {
              temp = std::abs(vn1[b_i - 1]);
              for (k = 2; k <= nmi; k++) {
                s = std::abs(vn1[(b_i + k) - 2]);
                if (s > temp) {
                  iy = k - 2;
                  temp = s;
                }
              }
            }
          }
          pvt = b_i + iy;
          if (pvt + 1 != b_i) {
            ix = pvt << 2;
            for (k = 0; k < mrows; k++) {
              temp_tmp = ix + k;
              temp = obj->QR[temp_tmp];
              iy = nfxd + k;
              obj->QR[temp_tmp] = obj->QR[iy];
              obj->QR[iy] = temp;
            }
            iy = obj->jpvt[pvt];
            obj->jpvt[pvt] = obj->jpvt[b_i - 1];
            obj->jpvt[b_i - 1] = iy;
            vn1[pvt] = vn1[b_i - 1];
            vn2[pvt] = vn2[b_i - 1];
          }
          if (b_i < mrows) {
            temp = obj->QR[ii];
            obj->tau[b_i - 1] =
                internal::reflapack::xzlarfg(mmi + 1, &temp, obj->QR, ii + 2);
            obj->QR[ii] = temp;
          } else {
            obj->tau[b_i - 1] = 0.0;
          }
          if (b_i < ncols) {
            temp = obj->QR[ii];
            obj->QR[ii] = 1.0;
            internal::reflapack::xzlarf(mmi + 1, nmi - 1, ii + 1,
                                        obj->tau[b_i - 1], obj->QR, ii + 5,
                                        work);
            obj->QR[ii] = temp;
          }
          for (pvt = ip1; pvt <= ncols; pvt++) {
            iy = b_i + ((pvt - 1) << 2);
            temp = vn1[pvt - 1];
            if (temp != 0.0) {
              double temp2;
              s = std::abs(obj->QR[iy - 1]) / temp;
              s = 1.0 - s * s;
              if (s < 0.0) {
                s = 0.0;
              }
              temp2 = temp / vn2[pvt - 1];
              temp2 = s * (temp2 * temp2);
              if (temp2 <= 1.4901161193847656E-8) {
                if (b_i < mrows) {
                  temp = internal::blas::xnrm2(mmi, obj->QR, iy + 1);
                  vn1[pvt - 1] = temp;
                  vn2[pvt - 1] = temp;
                } else {
                  vn1[pvt - 1] = 0.0;
                  vn2[pvt - 1] = 0.0;
                }
              } else {
                vn1[pvt - 1] = temp * std::sqrt(s);
              }
            }
          }
        }
      }
    }
  }
}

//
// Arguments    : boolean_T obj_hasLinear
//                int obj_nvar
//                double workspace[4]
//                const double H[9]
//                const double f[3]
//                const double x[4]
// Return Type  : void
//
} // namespace QRManager
namespace qpactiveset {
namespace Objective {
static void b_linearForm_(boolean_T obj_hasLinear, int obj_nvar,
                          double workspace[4], const double H[9],
                          const double f[3], const double x[4])
{
  int ix;
  ix = 0;
  if (obj_hasLinear) {
    if (0 <= obj_nvar - 1) {
      std::copy(&f[0], &f[obj_nvar], &workspace[0]);
    }
    ix = 1;
  }
  if (obj_nvar != 0) {
    int i;
    if ((ix != 1) && (0 <= obj_nvar - 1)) {
      std::memset(&workspace[0], 0, obj_nvar * sizeof(double));
    }
    ix = 0;
    i = obj_nvar * (obj_nvar - 1) + 1;
    for (int iac{1}; obj_nvar < 0 ? iac >= i : iac <= i; iac += obj_nvar) {
      int i1;
      i1 = (iac + obj_nvar) - 1;
      for (int ia{iac}; ia <= i1; ia++) {
        int i2;
        i2 = ia - iac;
        workspace[i2] += H[ia - 1] * x[ix];
      }
      ix++;
    }
  }
}

//
// Arguments    : const b_struct_T *obj
//                double workspace[20]
//                const double H[9]
//                const double f[3]
//                const double x[4]
// Return Type  : double
//
static double computeFval(const b_struct_T *obj, double workspace[20],
                          const double H[9], const double f[3],
                          const double x[4])
{
  double val;
  switch (obj->objtype) {
  case 5:
    val = obj->gammaScalar * x[obj->nvar - 1];
    break;
  case 3: {
    linearForm_(obj->hasLinear, obj->nvar, workspace, H, f, x);
    val = 0.0;
    if (obj->nvar >= 1) {
      int ixlast;
      ixlast = obj->nvar;
      for (int idx{0}; idx < ixlast; idx++) {
        val += x[idx] * workspace[idx];
      }
    }
  } break;
  default: {
    int ixlast;
    linearForm_(obj->hasLinear, obj->nvar, workspace, H, f, x);
    ixlast = obj->nvar + 1;
    for (int idx{ixlast}; idx < 4; idx++) {
      workspace[idx - 1] = 0.0 * x[idx - 1];
    }
    val = (x[0] * workspace[0] + x[1] * workspace[1]) + x[2] * workspace[2];
  } break;
  }
  return val;
}

//
// Arguments    : const b_struct_T *obj
//                double workspace[20]
//                const double f[3]
//                const double x[4]
// Return Type  : double
//
static double computeFval_ReuseHx(const b_struct_T *obj, double workspace[20],
                                  const double f[3], const double x[4])
{
  double val;
  switch (obj->objtype) {
  case 5:
    val = obj->gammaScalar * x[obj->nvar - 1];
    break;
  case 3: {
    if (obj->hasLinear) {
      int idx;
      int ixlast;
      ixlast = obj->nvar;
      for (idx = 0; idx < ixlast; idx++) {
        workspace[idx] = 0.5 * obj->Hx[idx] + f[idx];
      }
      val = 0.0;
      if (obj->nvar >= 1) {
        ixlast = obj->nvar;
        for (idx = 0; idx < ixlast; idx++) {
          val += x[idx] * workspace[idx];
        }
      }
    } else {
      val = 0.0;
      if (obj->nvar >= 1) {
        int ixlast;
        ixlast = obj->nvar;
        for (int idx{0}; idx < ixlast; idx++) {
          val += x[idx] * obj->Hx[idx];
        }
      }
      val *= 0.5;
    }
  } break;
  default: {
    if (obj->hasLinear) {
      int ixlast;
      ixlast = obj->nvar;
      if (0 <= ixlast - 1) {
        std::copy(&f[0], &f[ixlast], &workspace[0]);
      }
      ixlast = 2 - obj->nvar;
      for (int idx{0}; idx <= ixlast; idx++) {
        workspace[obj->nvar + idx] = 0.0;
      }
      workspace[0] += 0.5 * obj->Hx[0];
      workspace[1] += 0.5 * obj->Hx[1];
      workspace[2] += 0.5 * obj->Hx[2];
      val = (x[0] * workspace[0] + x[1] * workspace[1]) + x[2] * workspace[2];
    } else {
      int ixlast;
      val = 0.5 * ((x[0] * obj->Hx[0] + x[1] * obj->Hx[1]) + x[2] * obj->Hx[2]);
      ixlast = obj->nvar + 1;
      for (int idx{ixlast}; idx < 4; idx++) {
        val += x[idx - 1] * 0.0;
      }
    }
  } break;
  }
  return val;
}

//
// Arguments    : b_struct_T *obj
//                const double H[9]
//                const double f[3]
//                const double x[4]
// Return Type  : void
//
static void computeGrad_StoreHx(b_struct_T *obj, const double H[9],
                                const double f[3], const double x[4])
{
  switch (obj->objtype) {
  case 5: {
    int i;
    i = obj->nvar;
    if (0 <= i - 2) {
      std::memset(&obj->grad[0], 0, (i + -1) * sizeof(double));
    }
    obj->grad[obj->nvar - 1] = obj->gammaScalar;
  } break;
  case 3: {
    int i;
    int lda;
    int m_tmp_tmp;
    m_tmp_tmp = obj->nvar - 1;
    lda = obj->nvar;
    if (obj->nvar != 0) {
      int ix;
      if (0 <= m_tmp_tmp) {
        std::memset(&obj->Hx[0], 0, (m_tmp_tmp + 1) * sizeof(double));
      }
      ix = 0;
      i = obj->nvar * (obj->nvar - 1) + 1;
      for (int iac{1}; lda < 0 ? iac >= i : iac <= i; iac += lda) {
        int i1;
        i1 = iac + m_tmp_tmp;
        for (int ia{iac}; ia <= i1; ia++) {
          int i2;
          i2 = ia - iac;
          obj->Hx[i2] += H[ia - 1] * x[ix];
        }
        ix++;
      }
    }
    i = obj->nvar;
    if (0 <= i - 1) {
      std::copy(&obj->Hx[0], &obj->Hx[i], &obj->grad[0]);
    }
    if (obj->hasLinear && (obj->nvar >= 1)) {
      i = obj->nvar - 1;
      for (m_tmp_tmp = 0; m_tmp_tmp <= i; m_tmp_tmp++) {
        obj->grad[m_tmp_tmp] += f[m_tmp_tmp];
      }
    }
  } break;
  default: {
    int i;
    int lda;
    int m_tmp_tmp;
    m_tmp_tmp = obj->nvar - 1;
    lda = obj->nvar;
    if (obj->nvar != 0) {
      int ix;
      if (0 <= m_tmp_tmp) {
        std::memset(&obj->Hx[0], 0, (m_tmp_tmp + 1) * sizeof(double));
      }
      ix = 0;
      i = obj->nvar * (obj->nvar - 1) + 1;
      for (int iac{1}; lda < 0 ? iac >= i : iac <= i; iac += lda) {
        int i1;
        i1 = iac + m_tmp_tmp;
        for (int ia{iac}; ia <= i1; ia++) {
          int i2;
          i2 = ia - iac;
          obj->Hx[i2] += H[ia - 1] * x[ix];
        }
        ix++;
      }
    }
    i = obj->nvar + 1;
    for (m_tmp_tmp = i; m_tmp_tmp < 4; m_tmp_tmp++) {
      obj->Hx[m_tmp_tmp - 1] = 0.0 * x[m_tmp_tmp - 1];
    }
    obj->grad[0] = obj->Hx[0];
    obj->grad[1] = obj->Hx[1];
    obj->grad[2] = obj->Hx[2];
    if (obj->hasLinear && (obj->nvar >= 1)) {
      i = obj->nvar - 1;
      for (m_tmp_tmp = 0; m_tmp_tmp <= i; m_tmp_tmp++) {
        obj->grad[m_tmp_tmp] += f[m_tmp_tmp];
      }
    }
  } break;
  }
}

//
// Arguments    : boolean_T obj_hasLinear
//                int obj_nvar
//                double workspace[20]
//                const double H[9]
//                const double f[3]
//                const double x[4]
// Return Type  : void
//
static void linearForm_(boolean_T obj_hasLinear, int obj_nvar,
                        double workspace[20], const double H[9],
                        const double f[3], const double x[4])
{
  int ix;
  ix = 0;
  if (obj_hasLinear) {
    if (0 <= obj_nvar - 1) {
      std::copy(&f[0], &f[obj_nvar], &workspace[0]);
    }
    ix = 1;
  }
  if (obj_nvar != 0) {
    int i;
    if ((ix != 1) && (0 <= obj_nvar - 1)) {
      std::memset(&workspace[0], 0, obj_nvar * sizeof(double));
    }
    ix = 0;
    i = obj_nvar * (obj_nvar - 1) + 1;
    for (int iac{1}; obj_nvar < 0 ? iac >= i : iac <= i; iac += obj_nvar) {
      double c;
      int i1;
      c = 0.5 * x[ix];
      i1 = (iac + obj_nvar) - 1;
      for (int ia{iac}; ia <= i1; ia++) {
        int i2;
        i2 = ia - iac;
        workspace[i2] += H[ia - 1] * c;
      }
      ix++;
    }
  }
}

//
// Arguments    : f_struct_T *obj
//                int TYPE
//                int idx_local
// Return Type  : void
//
} // namespace Objective
namespace WorkingSet {
static void addBoundToActiveSetMatrix_(f_struct_T *obj, int TYPE, int idx_local)
{
  int colOffset;
  int i;
  int idx_bnd_local;
  obj->nWConstr[TYPE - 1]++;
  obj->isActiveConstr[(obj->isActiveIdx[TYPE - 1] + idx_local) - 2] = true;
  obj->nActiveConstr++;
  obj->Wid[obj->nActiveConstr - 1] = TYPE;
  obj->Wlocalidx[obj->nActiveConstr - 1] = idx_local;
  colOffset = ((obj->nActiveConstr - 1) << 2) - 1;
  if (TYPE != 5) {
    idx_bnd_local = obj->indexLB[idx_local - 1];
    obj->bwset[obj->nActiveConstr - 1] = obj->lb[idx_bnd_local - 1];
  } else {
    // A check that is always false is detected at compile-time. Eliminating
    // code that follows.
  }
  if (0 <= idx_bnd_local - 2) {
    std::memset(&obj->ATwset[colOffset + 1], 0,
                (((idx_bnd_local + colOffset) - colOffset) + -1) *
                    sizeof(double));
  }
  obj->ATwset[idx_bnd_local + colOffset] =
      2.0 * static_cast<double>(TYPE == 5) - 1.0;
  idx_bnd_local++;
  i = obj->nVar;
  if (idx_bnd_local <= i) {
    std::memset(&obj->ATwset[idx_bnd_local + colOffset], 0,
                ((((i + colOffset) - idx_bnd_local) - colOffset) + 1) *
                    sizeof(double));
  }
  switch (obj->probType) {
  case 3:
  case 2:
    break;
  default:
    obj->ATwset[obj->nVar + colOffset] = -1.0;
    break;
  }
}

//
// Arguments    : f_struct_T *obj
//                const double x[4]
// Return Type  : double
//
static double maxConstraintViolation(f_struct_T *obj, const double x[4])
{
  double v;
  int ia;
  int idxLB;
  int mLB;
  mLB = obj->sizes[3];
  if (obj->probType == 2) {
    obj->maxConstrWorkspace[0] = obj->bineq;
    obj->maxConstrWorkspace[0] = -obj->maxConstrWorkspace[0];
    obj->maxConstrWorkspace[0] +=
        (obj->Aineq[0] * x[0] + obj->Aineq[1] * x[1]) + obj->Aineq[2] * x[2];
    obj->maxConstrWorkspace[0] -= x[3];
    v = std::fmax(0.0, obj->maxConstrWorkspace[0]);
  } else {
    double c;
    obj->maxConstrWorkspace[0] = obj->bineq;
    obj->maxConstrWorkspace[0] = -obj->maxConstrWorkspace[0];
    c = 0.0;
    idxLB = obj->nVar;
    for (ia = 1; ia <= idxLB; ia++) {
      c += obj->Aineq[ia - 1] * x[ia - 1];
    }
    obj->maxConstrWorkspace[0] += c;
    v = std::fmax(0.0, obj->maxConstrWorkspace[0]);
  }
  if (obj->sizes[3] > 0) {
    for (ia = 0; ia < mLB; ia++) {
      idxLB = obj->indexLB[ia] - 1;
      v = std::fmax(v, -x[idxLB] - obj->lb[idxLB]);
    }
  }
  return v;
}

//
// Arguments    : f_struct_T *obj
//                int PROBLEM_TYPE
// Return Type  : void
//
static void setProblemType(f_struct_T *obj, int PROBLEM_TYPE)
{
  switch (PROBLEM_TYPE) {
  case 3: {
    int i;
    obj->nVar = 3;
    obj->mConstr = obj->mConstrOrig;
    for (i = 0; i < 5; i++) {
      obj->sizes[i] = obj->sizesNormal[i];
    }
    for (i = 0; i < 6; i++) {
      obj->isActiveIdx[i] = obj->isActiveIdxNormal[i];
    }
  } break;
  case 1: {
    int i;
    int idxStartIneq;
    obj->nVar = 4;
    obj->mConstr = obj->mConstrOrig + 1;
    for (i = 0; i < 5; i++) {
      obj->sizes[i] = obj->sizesPhaseOne[i];
    }
    for (i = 0; i < 6; i++) {
      obj->isActiveIdx[i] = obj->isActiveIdxPhaseOne[i];
    }
    obj->Aineq[3] = -1.0;
    obj->indexLB[obj->sizes[3] - 1] = 4;
    obj->lb[3] = obj->SLACK0;
    idxStartIneq = obj->isActiveIdx[2];
    i = obj->nActiveConstr;
    for (int idx{idxStartIneq}; idx <= i; idx++) {
      obj->ATwset[((idx - 1) << 2) + 3] = -1.0;
    }
    if (obj->nWConstr[4] > 0) {
      obj->isActiveConstr[obj->isActiveIdx[4] - 1] = false;
    }
    obj->isActiveConstr[obj->isActiveIdx[4] - 2] = false;
  } break;
  case 2: {
    int i;
    obj->nVar = 3;
    obj->mConstr = 4;
    for (i = 0; i < 5; i++) {
      obj->sizes[i] = obj->sizesRegularized[i];
    }
    if (obj->probType != 4) {
      int i1;
      int idx;
      int idxStartIneq;
      int idx_lb;
      obj->Aineq[3] = -1.0;
      idx_lb = 3;
      i = obj->sizesNormal[3] + 1;
      i1 = obj->sizesRegularized[3];
      for (idx = i; idx <= i1; idx++) {
        idx_lb++;
        obj->indexLB[idx - 1] = idx_lb;
      }
      i = obj->isActiveIdx[4];
      i1 = obj->isActiveIdxRegularized[4] - 1;
      if (i <= i1) {
        std::memset(&obj->isActiveConstr[i + -1], 0,
                    ((i1 - i) + 1) * sizeof(boolean_T));
      }
      obj->lb[3] = 0.0;
      idxStartIneq = obj->isActiveIdx[2];
      i = obj->nActiveConstr;
      for (idx = idxStartIneq; idx <= i; idx++) {
        idx_lb = ((idx - 1) << 2) - 1;
        if (obj->Wid[idx - 1] == 3) {
          i1 = obj->Wlocalidx[idx - 1] + 2;
          if (4 <= i1) {
            std::memset(&obj->ATwset[idx_lb + 4], 0,
                        (((i1 + idx_lb) - idx_lb) + -3) * sizeof(double));
          }
          obj->ATwset[(obj->Wlocalidx[idx - 1] + idx_lb) + 3] = -1.0;
          i1 = obj->Wlocalidx[idx - 1] + 4;
          if (i1 <= 3) {
            std::memset(&obj->ATwset[i1 + idx_lb], 0,
                        (((idx_lb - i1) - idx_lb) + 4) * sizeof(double));
          }
        }
      }
    }
    for (i = 0; i < 6; i++) {
      obj->isActiveIdx[i] = obj->isActiveIdxRegularized[i];
    }
  } break;
  default: {
    int i;
    int idxStartIneq;
    obj->nVar = 4;
    obj->mConstr = 5;
    for (i = 0; i < 5; i++) {
      obj->sizes[i] = obj->sizesRegPhaseOne[i];
    }
    for (i = 0; i < 6; i++) {
      obj->isActiveIdx[i] = obj->isActiveIdxRegPhaseOne[i];
    }
    obj->Aineq[3] = -1.0;
    obj->indexLB[obj->sizes[3] - 1] = 4;
    obj->lb[3] = obj->SLACK0;
    idxStartIneq = obj->isActiveIdx[2];
    i = obj->nActiveConstr;
    for (int idx{idxStartIneq}; idx <= i; idx++) {
      obj->ATwset[((idx - 1) << 2) + 3] = -1.0;
    }
    if (obj->nWConstr[4] > 0) {
      obj->isActiveConstr[obj->isActiveIdx[4] - 1] = false;
    }
    obj->isActiveConstr[obj->isActiveIdx[4] - 2] = false;
  } break;
  }
  obj->probType = PROBLEM_TYPE;
}

//
// Arguments    : const double H[9]
//                struct_T *solution
//                d_struct_T *memspace
//                const e_struct_T *qrmanager
//                c_struct_T *cholmanager
//                const b_struct_T *objective
// Return Type  : void
//
} // namespace WorkingSet
static void compute_deltax(const double H[9], struct_T *solution,
                           d_struct_T *memspace, const e_struct_T *qrmanager,
                           c_struct_T *cholmanager, const b_struct_T *objective)
{
  int mNull_tmp;
  int nVar_tmp;
  nVar_tmp = qrmanager->mrows - 1;
  mNull_tmp = qrmanager->mrows - qrmanager->ncols;
  if (mNull_tmp <= 0) {
    if (0 <= nVar_tmp) {
      std::memset(&solution->searchDir[0], 0, (nVar_tmp + 1) * sizeof(double));
    }
  } else {
    int nVars;
    for (nVars = 0; nVars <= nVar_tmp; nVars++) {
      solution->searchDir[nVars] = -objective->grad[nVars];
    }
    if (qrmanager->ncols <= 0) {
      if (objective->objtype == 3) {
        double temp;
        int A_maxDiag_idx;
        int br;
        int lastColC;
        temp = 1.4901161193847656E-6 * static_cast<double>(qrmanager->mrows);
        cholmanager->ndims = qrmanager->mrows;
        for (nVars = 0; nVars <= nVar_tmp; nVars++) {
          A_maxDiag_idx = (nVar_tmp + 1) * nVars;
          lastColC = nVars << 2;
          for (br = 0; br <= nVar_tmp; br++) {
            cholmanager->FMat[lastColC + br] = H[A_maxDiag_idx + br];
          }
        }
        if (qrmanager->mrows < 1) {
          A_maxDiag_idx = -1;
        } else {
          A_maxDiag_idx = 0;
          if (qrmanager->mrows > 1) {
            double smax;
            smax = std::abs(cholmanager->FMat[0]);
            for (br = 2; br <= nVar_tmp + 1; br++) {
              double s;
              s = std::abs(cholmanager->FMat[(br - 1) * 5]);
              if (s > smax) {
                A_maxDiag_idx = br - 1;
                smax = s;
              }
            }
          }
        }
        cholmanager->regTol_ = std::fmax(
            std::abs(cholmanager->FMat[A_maxDiag_idx + (A_maxDiag_idx << 2)]) *
                2.2204460492503131E-16,
            std::abs(temp));
        DynamicRegCholManager::fullColLDL2_(cholmanager, qrmanager->mrows,
                                            temp);
        if (cholmanager->ConvexCheck) {
          nVars = 0;
          int exitg1;
          do {
            exitg1 = 0;
            if (nVars <= nVar_tmp) {
              if (cholmanager->FMat[nVars + (nVars << 2)] <= 0.0) {
                cholmanager->info = -nVars - 1;
                exitg1 = 1;
              } else {
                nVars++;
              }
            } else {
              cholmanager->ConvexCheck = false;
              exitg1 = 1;
            }
          } while (exitg1 == 0);
        }
        if (cholmanager->info != 0) {
          solution->state = -6;
        } else {
          int ar;
          int i;
          nVars = cholmanager->ndims - 2;
          if (cholmanager->ndims != 0) {
            for (br = 0; br <= nVars + 1; br++) {
              A_maxDiag_idx = br + (br << 2);
              i = nVars - br;
              for (ar = 0; ar <= i; ar++) {
                lastColC = (br + ar) + 1;
                solution->searchDir[lastColC] -=
                    solution->searchDir[br] *
                    cholmanager->FMat[(A_maxDiag_idx + ar) + 1];
              }
            }
          }
          i = cholmanager->ndims;
          for (nVars = 0; nVars < i; nVars++) {
            solution->searchDir[nVars] /=
                cholmanager->FMat[nVars + (nVars << 2)];
          }
          nVars = cholmanager->ndims;
          if (cholmanager->ndims != 0) {
            for (br = nVars; br >= 1; br--) {
              lastColC = (br - 1) << 2;
              temp = solution->searchDir[br - 1];
              i = br + 1;
              for (ar = nVars; ar >= i; ar--) {
                temp -= cholmanager->FMat[(lastColC + ar) - 1] *
                        solution->searchDir[ar - 1];
              }
              solution->searchDir[br - 1] = temp;
            }
          }
        }
      }
    } else {
      int nullStartIdx;
      int nullStartIdx_tmp;
      nullStartIdx_tmp = qrmanager->ncols << 2;
      nullStartIdx = nullStartIdx_tmp + 1;
      if (objective->objtype == 5) {
        for (nVars = 0; nVars < mNull_tmp; nVars++) {
          memspace->workspace_double[nVars] =
              -qrmanager->Q[nVar_tmp + ((qrmanager->ncols + nVars) << 2)];
        }
        if (qrmanager->mrows != 0) {
          int i;
          int lastColC;
          if (0 <= nVar_tmp) {
            std::memset(&solution->searchDir[0], 0,
                        (nVar_tmp + 1) * sizeof(double));
          }
          lastColC = 0;
          i = (nullStartIdx_tmp + ((mNull_tmp - 1) << 2)) + 1;
          for (int A_maxDiag_idx{nullStartIdx}; A_maxDiag_idx <= i;
               A_maxDiag_idx += 4) {
            int i1;
            i1 = A_maxDiag_idx + nVar_tmp;
            for (nVars = A_maxDiag_idx; nVars <= i1; nVars++) {
              int i2;
              i2 = nVars - A_maxDiag_idx;
              solution->searchDir[i2] += qrmanager->Q[nVars - 1] *
                                         memspace->workspace_double[lastColC];
            }
            lastColC++;
          }
        }
      } else {
        double temp;
        int A_maxDiag_idx;
        int ar;
        int br;
        int i;
        int i1;
        int i2;
        int lastColC;
        if (objective->objtype == 3) {
          int cr;
          int ic;
          nVars = qrmanager->mrows;
          if (qrmanager->mrows != 0) {
            br = nullStartIdx_tmp;
            lastColC = 5 * (mNull_tmp - 1);
            for (cr = 0; cr <= lastColC; cr += 5) {
              i = cr + 1;
              i1 = cr + nVars;
              if (i <= i1) {
                std::memset(&memspace->workspace_double[i + -1], 0,
                            ((i1 - i) + 1) * sizeof(double));
              }
            }
            for (cr = 0; cr <= lastColC; cr += 5) {
              ar = -1;
              i = br + 1;
              i1 = br + nVars;
              for (int ib{i}; ib <= i1; ib++) {
                i2 = cr + 1;
                A_maxDiag_idx = cr + nVars;
                for (ic = i2; ic <= A_maxDiag_idx; ic++) {
                  memspace->workspace_double[ic - 1] +=
                      qrmanager->Q[ib - 1] * H[(ar + ic) - cr];
                }
                ar += nVars;
              }
              br += 4;
            }
          }
          lastColC = (mNull_tmp - 1) << 2;
          for (cr = 0; cr <= lastColC; cr += 4) {
            i = cr + 1;
            i1 = cr + mNull_tmp;
            if (i <= i1) {
              std::memset(&cholmanager->FMat[i + -1], 0,
                          ((i1 - i) + 1) * sizeof(double));
            }
          }
          br = -1;
          for (cr = 0; cr <= lastColC; cr += 4) {
            ar = nullStartIdx_tmp;
            i = cr + 1;
            i1 = cr + mNull_tmp;
            for (ic = i; ic <= i1; ic++) {
              temp = 0.0;
              for (A_maxDiag_idx = 0; A_maxDiag_idx < nVars; A_maxDiag_idx++) {
                temp += qrmanager->Q[A_maxDiag_idx + ar] *
                        memspace->workspace_double[(A_maxDiag_idx + br) + 1];
              }
              cholmanager->FMat[ic - 1] += temp;
              ar += 4;
            }
            br += 5;
          }
        }
        temp = 1.4901161193847656E-6 * static_cast<double>(mNull_tmp);
        cholmanager->ndims = mNull_tmp;
        A_maxDiag_idx = 0;
        if (mNull_tmp > 1) {
          double smax;
          smax = std::abs(cholmanager->FMat[0]);
          for (br = 2; br <= mNull_tmp; br++) {
            double s;
            s = std::abs(cholmanager->FMat[(br - 1) * 5]);
            if (s > smax) {
              A_maxDiag_idx = br - 1;
              smax = s;
            }
          }
        }
        cholmanager->regTol_ = std::fmax(
            std::abs(cholmanager->FMat[A_maxDiag_idx + (A_maxDiag_idx << 2)]) *
                2.2204460492503131E-16,
            temp);
        DynamicRegCholManager::fullColLDL2_(cholmanager, mNull_tmp, temp);
        if (cholmanager->ConvexCheck) {
          nVars = 0;
          int exitg1;
          do {
            exitg1 = 0;
            if (nVars <= mNull_tmp - 1) {
              if (cholmanager->FMat[nVars + (nVars << 2)] <= 0.0) {
                cholmanager->info = -nVars - 1;
                exitg1 = 1;
              } else {
                nVars++;
              }
            } else {
              cholmanager->ConvexCheck = false;
              exitg1 = 1;
            }
          } while (exitg1 == 0);
        }
        if (cholmanager->info != 0) {
          solution->state = -6;
        } else {
          if (qrmanager->mrows != 0) {
            if (0 <= mNull_tmp - 1) {
              std::memset(&memspace->workspace_double[0], 0,
                          mNull_tmp * sizeof(double));
            }
            i = (nullStartIdx_tmp + ((mNull_tmp - 1) << 2)) + 1;
            for (A_maxDiag_idx = nullStartIdx; A_maxDiag_idx <= i;
                 A_maxDiag_idx += 4) {
              temp = 0.0;
              i1 = A_maxDiag_idx + nVar_tmp;
              for (nVars = A_maxDiag_idx; nVars <= i1; nVars++) {
                temp += qrmanager->Q[nVars - 1] *
                        objective->grad[nVars - A_maxDiag_idx];
              }
              i1 = ((A_maxDiag_idx - nullStartIdx_tmp) - 1) >> 2;
              memspace->workspace_double[i1] += -temp;
            }
          }
          nVars = cholmanager->ndims - 2;
          if (cholmanager->ndims != 0) {
            for (br = 0; br <= nVars + 1; br++) {
              A_maxDiag_idx = br + (br << 2);
              i = nVars - br;
              for (ar = 0; ar <= i; ar++) {
                lastColC = (br + ar) + 1;
                memspace->workspace_double[lastColC] -=
                    memspace->workspace_double[br] *
                    cholmanager->FMat[(A_maxDiag_idx + ar) + 1];
              }
            }
          }
          i = cholmanager->ndims;
          for (nVars = 0; nVars < i; nVars++) {
            memspace->workspace_double[nVars] /=
                cholmanager->FMat[nVars + (nVars << 2)];
          }
          nVars = cholmanager->ndims;
          if (cholmanager->ndims != 0) {
            for (br = nVars; br >= 1; br--) {
              lastColC = (br - 1) << 2;
              temp = memspace->workspace_double[br - 1];
              i = br + 1;
              for (ar = nVars; ar >= i; ar--) {
                temp -= cholmanager->FMat[(lastColC + ar) - 1] *
                        memspace->workspace_double[ar - 1];
              }
              memspace->workspace_double[br - 1] = temp;
            }
          }
          if (qrmanager->mrows != 0) {
            if (0 <= nVar_tmp) {
              std::memset(&solution->searchDir[0], 0,
                          (nVar_tmp + 1) * sizeof(double));
            }
            lastColC = 0;
            i = (nullStartIdx_tmp + ((mNull_tmp - 1) << 2)) + 1;
            for (A_maxDiag_idx = nullStartIdx; A_maxDiag_idx <= i;
                 A_maxDiag_idx += 4) {
              i1 = A_maxDiag_idx + nVar_tmp;
              for (nVars = A_maxDiag_idx; nVars <= i1; nVars++) {
                i2 = nVars - A_maxDiag_idx;
                solution->searchDir[i2] += qrmanager->Q[nVars - 1] *
                                           memspace->workspace_double[lastColC];
              }
              lastColC++;
            }
          }
        }
      }
    }
  }
}

//
// Arguments    : double workspace[20]
//                struct_T *solution
//                const b_struct_T *objective
//                const e_struct_T *qrmanager
// Return Type  : void
//
static void compute_lambda(double workspace[20], struct_T *solution,
                           const b_struct_T *objective,
                           const e_struct_T *qrmanager)
{
  int nActiveConstr_tmp;
  nActiveConstr_tmp = qrmanager->ncols;
  if (qrmanager->ncols > 0) {
    double c;
    int idx;
    int idxQR;
    boolean_T guard1{false};
    guard1 = false;
    if (objective->objtype != 4) {
      boolean_T nonDegenerate;
      c = 100.0 * static_cast<double>(qrmanager->mrows) *
          2.2204460492503131E-16;
      if ((qrmanager->mrows > 0) && (qrmanager->ncols > 0)) {
        nonDegenerate = true;
      } else {
        nonDegenerate = false;
      }
      if (nonDegenerate) {
        boolean_T guard2{false};
        idx = nActiveConstr_tmp;
        guard2 = false;
        if (qrmanager->mrows < qrmanager->ncols) {
          idxQR = qrmanager->mrows + ((qrmanager->ncols - 1) << 2);
          while ((idx > qrmanager->mrows) &&
                 (std::abs(qrmanager->QR[idxQR - 1]) >= c)) {
            idx--;
            idxQR -= 4;
          }
          nonDegenerate = (idx == qrmanager->mrows);
          if (nonDegenerate) {
            guard2 = true;
          }
        } else {
          guard2 = true;
        }
        if (guard2) {
          idxQR = idx + ((idx - 1) << 2);
          while ((idx >= 1) && (std::abs(qrmanager->QR[idxQR - 1]) >= c)) {
            idx--;
            idxQR -= 5;
          }
          nonDegenerate = (idx == 0);
        }
      }
      if (!nonDegenerate) {
        solution->state = -7;
      } else {
        guard1 = true;
      }
    } else {
      guard1 = true;
    }
    if (guard1) {
      int ia;
      int iac;
      if (qrmanager->mrows != 0) {
        if (0 <= nActiveConstr_tmp - 1) {
          std::memset(&workspace[0], 0, nActiveConstr_tmp * sizeof(double));
        }
        idxQR = ((qrmanager->ncols - 1) << 2) + 1;
        for (iac = 1; iac <= idxQR; iac += 4) {
          c = 0.0;
          idx = (iac + qrmanager->mrows) - 1;
          for (ia = iac; ia <= idx; ia++) {
            c += qrmanager->Q[ia - 1] * objective->grad[ia - iac];
          }
          idx = (iac - 1) >> 2;
          workspace[idx] += c;
        }
      }
      for (iac = nActiveConstr_tmp; iac >= 1; iac--) {
        idxQR = (iac + ((iac - 1) << 2)) - 1;
        workspace[iac - 1] /= qrmanager->QR[idxQR];
        for (ia = 0; ia <= iac - 2; ia++) {
          idx = (iac - ia) - 2;
          workspace[idx] -=
              workspace[iac - 1] * qrmanager->QR[(idxQR - ia) - 1];
        }
      }
      for (idx = 0; idx < nActiveConstr_tmp; idx++) {
        solution->lambda[idx] = -workspace[idx];
      }
    }
  }
}

//
// Arguments    : const double H[9]
//                const double f[3]
//                struct_T *solution
//                d_struct_T *memspace
//                f_struct_T *workingset
//                c_struct_T *cholmanager
//                int runTimeOptions_MaxIterations
//                double runTimeOptions_ConstrRelTolFactor
//                double runTimeOptions_ProbRelTolFactor
//                e_struct_T *qrmanager
//                b_struct_T *objective
// Return Type  : void
//
static void driver(const double H[9], const double f[3], struct_T *solution,
                   d_struct_T *memspace, f_struct_T *workingset,
                   c_struct_T *cholmanager, int runTimeOptions_MaxIterations,
                   double runTimeOptions_ConstrRelTolFactor,
                   double runTimeOptions_ProbRelTolFactor,
                   e_struct_T *qrmanager, b_struct_T *objective)
{
  static const char cv[128]{
      '\x00', '\x01',     '\x02', '\x03', '\x04', '\x05', '\x06', '\x07',
      '\x08', '	', '\x0a', '\x0b', '\x0c', '\x0d', '\x0e', '\x0f',
      '\x10', '\x11',     '\x12', '\x13', '\x14', '\x15', '\x16', '\x17',
      '\x18', '\x19',     '\x1a', '\x1b', '\x1c', '\x1d', '\x1e', '\x1f',
      ' ',    '!',        '\"',   '#',    '$',    '%',    '&',    '\'',
      '(',    ')',        '*',    '+',    ',',    '-',    '.',    '/',
      '0',    '1',        '2',    '3',    '4',    '5',    '6',    '7',
      '8',    '9',        ':',    ';',    '<',    '=',    '>',    '?',
      '@',    'a',        'b',    'c',    'd',    'e',    'f',    'g',
      'h',    'i',        'j',    'k',    'l',    'm',    'n',    'o',
      'p',    'q',        'r',    's',    't',    'u',    'v',    'w',
      'x',    'y',        'z',    '[',    '\\',   ']',    '^',    '_',
      '`',    'a',        'b',    'c',    'd',    'e',    'f',    'g',
      'h',    'i',        'j',    'k',    'l',    'm',    'n',    'o',
      'p',    'q',        'r',    's',    't',    'u',    'v',    'w',
      'x',    'y',        'z',    '{',    '|',    '}',    '~',    '\x7f'};
  static const char cv1[8]{'q', 'u', 'a', 'd', 'p', 'r', 'o', 'g'};
  static const char t1_SolverName[8]{'q', 'u', 'a', 'd', 'p', 'r', 'o', 'g'};
  g_struct_T options;
  int i;
  int idx_global;
  int nVar;
  boolean_T okWorkingSet;
  objective->grad[0] = 0.0;
  objective->grad[1] = 0.0;
  objective->grad[2] = 0.0;
  objective->grad[3] = 0.0;
  objective->Hx[0] = 0.0;
  objective->Hx[1] = 0.0;
  objective->Hx[2] = 0.0;
  objective->hasLinear = true;
  objective->nvar = 3;
  objective->maxVar = 4;
  objective->beta = 0.0;
  objective->rho = 0.0;
  objective->objtype = 3;
  objective->prev_objtype = 3;
  objective->prev_nvar = 0;
  objective->prev_hasLinear = false;
  objective->gammaScalar = 0.0;
  solution->iterations = 0;
  nVar = workingset->nVar - 1;
  solution->state = 82;
  qrmanager->ldq = 4;
  std::memset(&qrmanager->QR[0], 0, 20U * sizeof(double));
  std::memset(&qrmanager->Q[0], 0, 16U * sizeof(double));
  for (i = 0; i < 5; i++) {
    qrmanager->jpvt[i] = 0;
  }
  qrmanager->mrows = 0;
  qrmanager->ncols = 0;
  qrmanager->tau[0] = 0.0;
  qrmanager->tau[1] = 0.0;
  qrmanager->tau[2] = 0.0;
  qrmanager->tau[3] = 0.0;
  qrmanager->minRowCol = 0;
  qrmanager->usedPivoting = false;
  initialize::RemoveDependentIneq_(workingset, qrmanager, memspace, 100.0);
  okWorkingSet = initialize::feasibleX0ForWorkingSet(
      memspace->workspace_double, solution->xstar, workingset, qrmanager);
  if (!okWorkingSet) {
    initialize::RemoveDependentIneq_(workingset, qrmanager, memspace, 1000.0);
    okWorkingSet = initialize::feasibleX0ForWorkingSet(
        memspace->workspace_double, solution->xstar, workingset, qrmanager);
    if (!okWorkingSet) {
      solution->state = -7;
    }
  }
  for (idx_global = 0; idx_global < 8; idx_global++) {
    options.SolverName[idx_global] = t1_SolverName[idx_global];
  }
  if (solution->state >= 0) {
    int b_nVar;
    int idx;
    int idxEndIneq;
    boolean_T exitg1;
    boolean_T guard1{false};
    solution->iterations = 0;
    solution->maxConstr =
        WorkingSet::maxConstraintViolation(workingset, solution->xstar);
    guard1 = false;
    if (solution->maxConstr > 1.0E-8 * runTimeOptions_ConstrRelTolFactor) {
      b_nVar = workingset->nVar;
      solution->xstar[3] = solution->maxConstr + 1.0;
      WorkingSet::setProblemType(workingset, 1);
      i = (workingset->nWConstr[0] + workingset->nWConstr[1]) + 1;
      idxEndIneq = workingset->nActiveConstr;
      for (idx_global = i; idx_global <= idxEndIneq; idx_global++) {
        workingset->isActiveConstr
            [(workingset->isActiveIdx[workingset->Wid[idx_global - 1] - 1] +
              workingset->Wlocalidx[idx_global - 1]) -
             2] = false;
      }
      workingset->nWConstr[2] = 0;
      workingset->nWConstr[3] = 0;
      workingset->nWConstr[4] = 0;
      workingset->nActiveConstr =
          workingset->nWConstr[0] + workingset->nWConstr[1];
      objective->prev_objtype = 3;
      objective->prev_nvar = 3;
      objective->prev_hasLinear = true;
      objective->objtype = 5;
      objective->nvar = 4;
      objective->gammaScalar = 1.0;
      objective->hasLinear = true;
      solution->fstar = Objective::computeFval(
          objective, memspace->workspace_double, H, f, solution->xstar);
      solution->state = 5;
      iterate(H, f, solution, memspace, workingset, qrmanager, cholmanager,
              objective, 1.0E-8 * runTimeOptions_ConstrRelTolFactor,
              1.4901161193847657E-10, runTimeOptions_MaxIterations,
              runTimeOptions_ConstrRelTolFactor,
              runTimeOptions_ProbRelTolFactor, true);
      if (workingset->isActiveConstr
              [(workingset->isActiveIdx[3] + workingset->sizes[3]) - 2]) {
        idx = 0;
        exitg1 = false;
        while ((!exitg1) && (idx + 1 <= workingset->nActiveConstr)) {
          if ((workingset->Wid[idx] == 4) &&
              (workingset->Wlocalidx[idx] == workingset->sizes[3])) {
            idxEndIneq = workingset->Wid[idx] - 1;
            workingset->isActiveConstr
                [(workingset->isActiveIdx[workingset->Wid[idx] - 1] +
                  workingset->Wlocalidx[idx]) -
                 2] = false;
            workingset->Wid[idx] =
                workingset->Wid[workingset->nActiveConstr - 1];
            workingset->Wlocalidx[idx] =
                workingset->Wlocalidx[workingset->nActiveConstr - 1];
            idx_global = workingset->nVar;
            for (i = 0; i < idx_global; i++) {
              workingset->ATwset[i + (idx << 2)] =
                  workingset
                      ->ATwset[i + ((workingset->nActiveConstr - 1) << 2)];
            }
            workingset->bwset[idx] =
                workingset->bwset[workingset->nActiveConstr - 1];
            workingset->nActiveConstr--;
            workingset->nWConstr[idxEndIneq]--;
            exitg1 = true;
          } else {
            idx++;
          }
        }
      }
      i = workingset->nActiveConstr - 1;
      while ((i + 1 > 0) && (i + 1 > b_nVar)) {
        idxEndIneq = workingset->Wid[i] - 1;
        workingset
            ->isActiveConstr[(workingset->isActiveIdx[workingset->Wid[i] - 1] +
                              workingset->Wlocalidx[i]) -
                             2] = false;
        workingset->Wid[i] = workingset->Wid[workingset->nActiveConstr - 1];
        workingset->Wlocalidx[i] =
            workingset->Wlocalidx[workingset->nActiveConstr - 1];
        idx_global = workingset->nVar;
        for (idx = 0; idx < idx_global; idx++) {
          workingset->ATwset[idx + (i << 2)] =
              workingset->ATwset[idx + ((workingset->nActiveConstr - 1) << 2)];
        }
        workingset->bwset[i] = workingset->bwset[workingset->nActiveConstr - 1];
        workingset->nActiveConstr--;
        workingset->nWConstr[idxEndIneq]--;
        i--;
      }
      solution->maxConstr = solution->xstar[3];
      WorkingSet::setProblemType(workingset, 3);
      objective->objtype = objective->prev_objtype;
      objective->nvar = objective->prev_nvar;
      objective->hasLinear = objective->prev_hasLinear;
      if (solution->state != 0) {
        solution->maxConstr =
            WorkingSet::maxConstraintViolation(workingset, solution->xstar);
        if (solution->maxConstr > 1.0E-8 * runTimeOptions_ConstrRelTolFactor) {
          for (i = 0; i < 5; i++) {
            solution->lambda[i] = 0.0;
          }
          solution->fstar = Objective::computeFval(
              objective, memspace->workspace_double, H, f, solution->xstar);
          solution->state = -2;
        } else {
          if (solution->maxConstr > 0.0) {
            double maxConstr_new;
            if (0 <= nVar) {
              std::copy(&solution->xstar[0], &solution->xstar[nVar + 1],
                        &solution->searchDir[0]);
            }
            initialize::PresolveWorkingSet(solution, memspace, workingset,
                                           qrmanager);
            maxConstr_new =
                WorkingSet::maxConstraintViolation(workingset, solution->xstar);
            if (maxConstr_new >= solution->maxConstr) {
              solution->maxConstr = maxConstr_new;
              if (0 <= nVar) {
                std::copy(&solution->searchDir[0],
                          &solution->searchDir[nVar + 1], &solution->xstar[0]);
              }
            }
          }
          guard1 = true;
        }
      }
    } else {
      guard1 = true;
    }
    if (guard1) {
      iterate(H, f, solution, memspace, workingset, qrmanager, cholmanager,
              objective, -1.0E+20, 1.0E-8, runTimeOptions_MaxIterations,
              runTimeOptions_ConstrRelTolFactor,
              runTimeOptions_ProbRelTolFactor, true);
      okWorkingSet = false;
      i = 0;
      int exitg2;
      do {
        exitg2 = 0;
        if (i < 8) {
          if (cv[static_cast<int>(options.SolverName[i])] !=
              cv[static_cast<int>(cv1[i])]) {
            exitg2 = 1;
          } else {
            i++;
          }
        } else {
          okWorkingSet = true;
          exitg2 = 1;
        }
      } while (exitg2 == 0);
      if (okWorkingSet && (solution->state != -6)) {
        solution->maxConstr =
            WorkingSet::maxConstraintViolation(workingset, solution->xstar);
        parseoutput::computeFirstOrderOpt(
            solution, objective, workingset->nVar, workingset->ATwset,
            workingset->nActiveConstr, memspace->workspace_double);
        while ((solution->iterations < runTimeOptions_MaxIterations) &&
               ((solution->state == -7) ||
                ((solution->state == 1) &&
                 ((solution->maxConstr >
                   1.0E-8 * runTimeOptions_ConstrRelTolFactor) ||
                  (solution->firstorderopt >
                   1.0E-8 * runTimeOptions_ProbRelTolFactor))))) {
          initialize::feasibleX0ForWorkingSet(memspace->workspace_double,
                                              solution->xstar, workingset,
                                              qrmanager);
          initialize::PresolveWorkingSet(solution, memspace, workingset,
                                         qrmanager);
          b_nVar = workingset->probType;
          nVar = workingset->nVar;
          solution->xstar[3] = solution->maxConstr + 1.0;
          if (workingset->probType == 3) {
            idxEndIneq = 1;
          } else {
            idxEndIneq = 4;
          }
          WorkingSet::setProblemType(workingset, idxEndIneq);
          i = (workingset->nWConstr[0] + workingset->nWConstr[1]) + 1;
          idxEndIneq = workingset->nActiveConstr;
          for (idx_global = i; idx_global <= idxEndIneq; idx_global++) {
            workingset->isActiveConstr
                [(workingset->isActiveIdx[workingset->Wid[idx_global - 1] - 1] +
                  workingset->Wlocalidx[idx_global - 1]) -
                 2] = false;
          }
          workingset->nWConstr[2] = 0;
          workingset->nWConstr[3] = 0;
          workingset->nWConstr[4] = 0;
          workingset->nActiveConstr =
              workingset->nWConstr[0] + workingset->nWConstr[1];
          objective->prev_objtype = objective->objtype;
          objective->prev_nvar = objective->nvar;
          objective->prev_hasLinear = objective->hasLinear;
          objective->objtype = 5;
          objective->nvar = 4;
          objective->gammaScalar = 1.0;
          objective->hasLinear = true;
          solution->fstar = Objective::computeFval(
              objective, memspace->workspace_double, H, f, solution->xstar);
          solution->state = 5;
          iterate(H, f, solution, memspace, workingset, qrmanager, cholmanager,
                  objective, 1.0E-8 * runTimeOptions_ConstrRelTolFactor,
                  1.4901161193847657E-10, runTimeOptions_MaxIterations,
                  runTimeOptions_ConstrRelTolFactor,
                  runTimeOptions_ProbRelTolFactor, false);
          if (workingset->isActiveConstr
                  [(workingset->isActiveIdx[3] + workingset->sizes[3]) - 2]) {
            idx = 0;
            exitg1 = false;
            while ((!exitg1) && (idx + 1 <= workingset->nActiveConstr)) {
              if ((workingset->Wid[idx] == 4) &&
                  (workingset->Wlocalidx[idx] == workingset->sizes[3])) {
                idxEndIneq = workingset->Wid[idx] - 1;
                workingset->isActiveConstr
                    [(workingset->isActiveIdx[workingset->Wid[idx] - 1] +
                      workingset->Wlocalidx[idx]) -
                     2] = false;
                workingset->Wid[idx] =
                    workingset->Wid[workingset->nActiveConstr - 1];
                workingset->Wlocalidx[idx] =
                    workingset->Wlocalidx[workingset->nActiveConstr - 1];
                idx_global = workingset->nVar;
                for (i = 0; i < idx_global; i++) {
                  workingset->ATwset[i + (idx << 2)] =
                      workingset
                          ->ATwset[i + ((workingset->nActiveConstr - 1) << 2)];
                }
                workingset->bwset[idx] =
                    workingset->bwset[workingset->nActiveConstr - 1];
                workingset->nActiveConstr--;
                workingset->nWConstr[idxEndIneq]--;
                exitg1 = true;
              } else {
                idx++;
              }
            }
          }
          i = workingset->nActiveConstr - 1;
          while ((i + 1 > 0) && (i + 1 > nVar)) {
            idxEndIneq = workingset->Wid[i] - 1;
            workingset->isActiveConstr
                [(workingset->isActiveIdx[workingset->Wid[i] - 1] +
                  workingset->Wlocalidx[i]) -
                 2] = false;
            workingset->Wid[i] = workingset->Wid[workingset->nActiveConstr - 1];
            workingset->Wlocalidx[i] =
                workingset->Wlocalidx[workingset->nActiveConstr - 1];
            idx_global = workingset->nVar;
            for (idx = 0; idx < idx_global; idx++) {
              workingset->ATwset[idx + (i << 2)] =
                  workingset
                      ->ATwset[idx + ((workingset->nActiveConstr - 1) << 2)];
            }
            workingset->bwset[i] =
                workingset->bwset[workingset->nActiveConstr - 1];
            workingset->nActiveConstr--;
            workingset->nWConstr[idxEndIneq]--;
            i--;
          }
          solution->maxConstr = solution->xstar[3];
          WorkingSet::setProblemType(workingset, b_nVar);
          objective->objtype = objective->prev_objtype;
          objective->nvar = objective->prev_nvar;
          objective->hasLinear = objective->prev_hasLinear;
          iterate(H, f, solution, memspace, workingset, qrmanager, cholmanager,
                  objective, -1.0E+20, 1.0E-8, runTimeOptions_MaxIterations,
                  runTimeOptions_ConstrRelTolFactor,
                  runTimeOptions_ProbRelTolFactor, false);
          solution->maxConstr =
              WorkingSet::maxConstraintViolation(workingset, solution->xstar);
          parseoutput::computeFirstOrderOpt(
              solution, objective, workingset->nVar, workingset->ATwset,
              workingset->nActiveConstr, memspace->workspace_double);
        }
      }
    }
  }
}

//
// Arguments    : const double solution_xstar[4]
//                const double solution_searchDir[4]
//                double workspace[20]
//                int workingset_nVar
//                const double workingset_Aineq[4]
//                double workingset_bineq
//                const double workingset_lb[4]
//                const int workingset_indexLB[4]
//                const int workingset_sizes[5]
//                const int workingset_isActiveIdx[6]
//                const boolean_T workingset_isActiveConstr[5]
//                const int workingset_nWConstr[5]
//                boolean_T isPhaseOne
//                double *alpha
//                boolean_T *newBlocking
//                int *constrType
//                int *constrIdx
// Return Type  : void
//
static void feasibleratiotest(
    const double solution_xstar[4], const double solution_searchDir[4],
    double workspace[20], int workingset_nVar, const double workingset_Aineq[4],
    double workingset_bineq, const double workingset_lb[4],
    const int workingset_indexLB[4], const int workingset_sizes[5],
    const int workingset_isActiveIdx[6],
    const boolean_T workingset_isActiveConstr[5],
    const int workingset_nWConstr[5], boolean_T isPhaseOne, double *alpha,
    boolean_T *newBlocking, int *constrType, int *constrIdx)
{
  double b_c;
  double c;
  double denomTol;
  double phaseOneCorrectionP;
  int ia;
  *alpha = 1.0E+30;
  *newBlocking = false;
  *constrType = 0;
  *constrIdx = 0;
  denomTol = 2.2204460492503131E-13 *
             internal::blas::xnrm2(workingset_nVar, solution_searchDir);
  if (workingset_nWConstr[2] < 1) {
    workspace[0] = workingset_bineq;
    workspace[0] = -workspace[0];
    b_c = 0.0;
    workspace[5] = 0.0;
    c = 0.0;
    for (ia = 1; ia <= workingset_nVar; ia++) {
      phaseOneCorrectionP = workingset_Aineq[ia - 1];
      b_c += phaseOneCorrectionP * solution_xstar[ia - 1];
      c += phaseOneCorrectionP * solution_searchDir[ia - 1];
    }
    workspace[0] += b_c;
    workspace[5] += c;
    if ((workspace[5] > denomTol) &&
        (!workingset_isActiveConstr[workingset_isActiveIdx[2] - 1])) {
      b_c = std::fmin(std::abs(workspace[0]), 1.0E-8 - workspace[0]) /
            workspace[5];
      if (b_c < 1.0E+30) {
        *alpha = b_c;
        *constrType = 3;
        *constrIdx = 1;
        *newBlocking = true;
      }
    }
  }
  if (workingset_nWConstr[3] < workingset_sizes[3]) {
    double ratio;
    c = static_cast<double>(isPhaseOne) * solution_xstar[workingset_nVar - 1];
    phaseOneCorrectionP = static_cast<double>(isPhaseOne) *
                          solution_searchDir[workingset_nVar - 1];
    ia = workingset_sizes[3];
    for (int idx{0}; idx <= ia - 2; idx++) {
      int i;
      i = workingset_indexLB[idx];
      b_c = -solution_searchDir[i - 1] - phaseOneCorrectionP;
      if ((b_c > denomTol) &&
          (!workingset_isActiveConstr[(workingset_isActiveIdx[3] + idx) - 1])) {
        ratio = (-solution_xstar[i - 1] - workingset_lb[i - 1]) - c;
        b_c = std::fmin(std::abs(ratio), 1.0E-8 - ratio) / b_c;
        if (b_c < *alpha) {
          *alpha = b_c;
          *constrType = 4;
          *constrIdx = idx + 1;
          *newBlocking = true;
        }
      }
    }
    ia = workingset_indexLB[workingset_sizes[3] - 1] - 1;
    phaseOneCorrectionP = -solution_searchDir[ia];
    if ((phaseOneCorrectionP > denomTol) &&
        (!workingset_isActiveConstr
             [(workingset_isActiveIdx[3] + workingset_sizes[3]) - 2])) {
      ratio = -solution_xstar[ia] - workingset_lb[ia];
      b_c = std::fmin(std::abs(ratio), 1.0E-8 - ratio) / phaseOneCorrectionP;
      if (b_c < *alpha) {
        *alpha = b_c;
        *constrType = 4;
        *constrIdx = workingset_sizes[3];
        *newBlocking = true;
      }
    }
  }
  if (!isPhaseOne) {
    if ((*newBlocking) && (*alpha > 1.0)) {
      *newBlocking = false;
    }
    *alpha = std::fmin(*alpha, 1.0);
  }
}

//
// Arguments    : struct_T *solution
//                d_struct_T *memspace
//                f_struct_T *workingset
//                e_struct_T *qrmanager
// Return Type  : void
//
namespace initialize {
static void PresolveWorkingSet(struct_T *solution, d_struct_T *memspace,
                               f_struct_T *workingset, e_struct_T *qrmanager)
{
  double tol;
  int idxDiag;
  int mTotalWorkingEq_tmp_tmp;
  int mWorkingFixed;
  int nDepInd;
  int nVar;
  int totalRank;
  solution->state = 82;
  nVar = workingset->nVar - 1;
  mWorkingFixed = workingset->nWConstr[0];
  mTotalWorkingEq_tmp_tmp = workingset->nWConstr[0] + workingset->nWConstr[1];
  nDepInd = 0;
  if (mTotalWorkingEq_tmp_tmp > 0) {
    int idx;
    for (totalRank = 0; totalRank < mTotalWorkingEq_tmp_tmp; totalRank++) {
      for (idxDiag = 0; idxDiag <= nVar; idxDiag++) {
        qrmanager->QR[totalRank + (idxDiag << 2)] =
            workingset->ATwset[idxDiag + (totalRank << 2)];
      }
    }
    nDepInd = mTotalWorkingEq_tmp_tmp - workingset->nVar;
    if (0 >= nDepInd) {
      nDepInd = 0;
    }
    if (0 <= nVar) {
      std::memset(&qrmanager->jpvt[0], 0, (nVar + 1) * sizeof(int));
    }
    QRManager::factorQRE(qrmanager, mTotalWorkingEq_tmp_tmp, workingset->nVar);
    tol =
        100.0 * static_cast<double>(workingset->nVar) * 2.2204460492503131E-16;
    totalRank = workingset->nVar;
    if (totalRank > mTotalWorkingEq_tmp_tmp) {
      totalRank = mTotalWorkingEq_tmp_tmp;
    }
    idxDiag = totalRank + ((totalRank - 1) << 2);
    while ((idxDiag > 0) && (std::abs(qrmanager->QR[idxDiag - 1]) < tol)) {
      idxDiag -= 5;
      nDepInd++;
    }
    if (nDepInd > 0) {
      boolean_T exitg1;
      QRManager::computeQ_(qrmanager, qrmanager->mrows);
      idx = 0;
      exitg1 = false;
      while ((!exitg1) && (idx <= nDepInd - 1)) {
        double qtb;
        totalRank = ((mTotalWorkingEq_tmp_tmp - idx) - 1) << 2;
        qtb = 0.0;
        for (idxDiag = 0; idxDiag < mTotalWorkingEq_tmp_tmp; idxDiag++) {
          qtb += qrmanager->Q[totalRank + idxDiag] * workingset->bwset[idxDiag];
        }
        if (std::abs(qtb) >= tol) {
          nDepInd = -1;
          exitg1 = true;
        } else {
          idx++;
        }
      }
    }
    if (nDepInd > 0) {
      for (idxDiag = 0; idxDiag < mTotalWorkingEq_tmp_tmp; idxDiag++) {
        totalRank = idxDiag << 2;
        if (0 <= nVar) {
          std::copy(&workingset->ATwset[totalRank],
                    &workingset->ATwset[(totalRank + nVar) + 1],
                    &qrmanager->QR[totalRank]);
        }
      }
      for (idx = 0; idx < mWorkingFixed; idx++) {
        qrmanager->jpvt[idx] = 1;
      }
      idxDiag = workingset->nWConstr[0] + 1;
      if (idxDiag <= mTotalWorkingEq_tmp_tmp) {
        std::memset(&qrmanager->jpvt[idxDiag + -1], 0,
                    ((mTotalWorkingEq_tmp_tmp - idxDiag) + 1) * sizeof(int));
      }
      QRManager::factorQRE(qrmanager, workingset->nVar,
                           mTotalWorkingEq_tmp_tmp);
      for (idx = 0; idx < nDepInd; idx++) {
        memspace->workspace_int[idx] =
            qrmanager->jpvt[(mTotalWorkingEq_tmp_tmp - nDepInd) + idx];
      }
      utils::countsort(memspace->workspace_int, nDepInd,
                       memspace->workspace_sort, 1, mTotalWorkingEq_tmp_tmp);
      for (idx = nDepInd; idx >= 1; idx--) {
        idxDiag = workingset->nWConstr[0] + workingset->nWConstr[1];
        if (idxDiag != 0) {
          totalRank = memspace->workspace_int[idx - 1];
          if (totalRank <= idxDiag) {
            if ((workingset->nActiveConstr == idxDiag) ||
                (totalRank == idxDiag)) {
              workingset->mEqRemoved++;
              // A check that is always false is detected at compile-time.
              // Eliminating code that follows.
            } else {
              workingset->mEqRemoved++;
              // A check that is always false is detected at compile-time.
              // Eliminating code that follows.
            }
          }
        }
      }
    }
  }
  if ((nDepInd != -1) && (workingset->nActiveConstr <= 4)) {
    boolean_T guard1{false};
    boolean_T okWorkingSet;
    RemoveDependentIneq_(workingset, qrmanager, memspace, 100.0);
    okWorkingSet = feasibleX0ForWorkingSet(
        memspace->workspace_double, solution->xstar, workingset, qrmanager);
    guard1 = false;
    if (!okWorkingSet) {
      RemoveDependentIneq_(workingset, qrmanager, memspace, 1000.0);
      okWorkingSet = feasibleX0ForWorkingSet(
          memspace->workspace_double, solution->xstar, workingset, qrmanager);
      if (!okWorkingSet) {
        solution->state = -7;
      } else {
        guard1 = true;
      }
    } else {
      guard1 = true;
    }
    if (guard1 && (workingset->nWConstr[0] + workingset->nWConstr[1] ==
                   workingset->nVar)) {
      tol = WorkingSet::maxConstraintViolation(workingset, solution->xstar);
      if (tol > 1.0E-8) {
        solution->state = -2;
      }
    }
  } else {
    solution->state = -3;
    totalRank = (workingset->nWConstr[0] + workingset->nWConstr[1]) + 1;
    idxDiag = workingset->nActiveConstr;
    for (nVar = totalRank; nVar <= idxDiag; nVar++) {
      workingset->isActiveConstr
          [(workingset->isActiveIdx[workingset->Wid[nVar - 1] - 1] +
            workingset->Wlocalidx[nVar - 1]) -
           2] = false;
    }
    workingset->nWConstr[2] = 0;
    workingset->nWConstr[3] = 0;
    workingset->nWConstr[4] = 0;
    workingset->nActiveConstr =
        workingset->nWConstr[0] + workingset->nWConstr[1];
  }
}

//
// Arguments    : f_struct_T *workingset
//                e_struct_T *qrmanager
//                d_struct_T *memspace
//                double tolfactor
// Return Type  : void
//
static void RemoveDependentIneq_(f_struct_T *workingset, e_struct_T *qrmanager,
                                 d_struct_T *memspace, double tolfactor)
{
  int nActiveConstr_tmp;
  int nFixedConstr;
  int nVar_tmp_tmp;
  nActiveConstr_tmp = workingset->nActiveConstr;
  nFixedConstr = workingset->nWConstr[0] + workingset->nWConstr[1];
  nVar_tmp_tmp = workingset->nVar;
  if ((workingset->nWConstr[2] + workingset->nWConstr[3]) +
          workingset->nWConstr[4] >
      0) {
    double tol;
    int idx;
    int idxDiag;
    int idx_col;
    int nDepIneq;
    tol = tolfactor * static_cast<double>(workingset->nVar) *
          2.2204460492503131E-16;
    for (idx = 0; idx < nFixedConstr; idx++) {
      qrmanager->jpvt[idx] = 1;
    }
    idx_col = nFixedConstr + 1;
    if (idx_col <= nActiveConstr_tmp) {
      std::memset(&qrmanager->jpvt[idx_col + -1], 0,
                  ((nActiveConstr_tmp - idx_col) + 1) * sizeof(int));
    }
    for (idx_col = 0; idx_col < nActiveConstr_tmp; idx_col++) {
      idxDiag = idx_col << 2;
      if (0 <= nVar_tmp_tmp - 1) {
        std::copy(
            &workingset->ATwset[idxDiag],
            &workingset->ATwset[idxDiag + ((nVar_tmp_tmp + idxDiag) - idxDiag)],
            &qrmanager->QR[idxDiag]);
      }
    }
    QRManager::factorQRE(qrmanager, workingset->nVar,
                         workingset->nActiveConstr);
    nDepIneq = 0;
    for (idx = workingset->nActiveConstr - 1; idx + 1 > nVar_tmp_tmp; idx--) {
      nDepIneq++;
      memspace->workspace_int[nDepIneq - 1] = qrmanager->jpvt[idx];
    }
    if (idx + 1 <= workingset->nVar) {
      idxDiag = idx + (idx << 2);
      while ((idx + 1 > nFixedConstr) &&
             (std::abs(qrmanager->QR[idxDiag]) < tol)) {
        nDepIneq++;
        memspace->workspace_int[nDepIneq - 1] = qrmanager->jpvt[idx];
        idx--;
        idxDiag -= 5;
      }
    }
    utils::countsort(memspace->workspace_int, nDepIneq,
                     memspace->workspace_sort, nFixedConstr + 1,
                     workingset->nActiveConstr);
    for (idx = nDepIneq; idx >= 1; idx--) {
      idxDiag = memspace->workspace_int[idx - 1] - 1;
      nActiveConstr_tmp = workingset->Wid[idxDiag] - 1;
      workingset->isActiveConstr[(workingset->isActiveIdx[nActiveConstr_tmp] +
                                  workingset->Wlocalidx[idxDiag]) -
                                 2] = false;
      workingset->Wid[idxDiag] = workingset->Wid[workingset->nActiveConstr - 1];
      workingset->Wlocalidx[idxDiag] =
          workingset->Wlocalidx[workingset->nActiveConstr - 1];
      idx_col = workingset->nVar;
      for (nVar_tmp_tmp = 0; nVar_tmp_tmp < idx_col; nVar_tmp_tmp++) {
        workingset->ATwset[nVar_tmp_tmp + (idxDiag << 2)] =
            workingset
                ->ATwset[nVar_tmp_tmp + ((workingset->nActiveConstr - 1) << 2)];
      }
      workingset->bwset[idxDiag] =
          workingset->bwset[workingset->nActiveConstr - 1];
      workingset->nActiveConstr--;
      workingset->nWConstr[nActiveConstr_tmp]--;
    }
  }
}

//
// Arguments    : double workspace[20]
//                double xCurrent[4]
//                f_struct_T *workingset
//                e_struct_T *qrmanager
// Return Type  : boolean_T
//
static boolean_T feasibleX0ForWorkingSet(double workspace[20],
                                         double xCurrent[4],
                                         f_struct_T *workingset,
                                         e_struct_T *qrmanager)
{
  double B[20];
  int mWConstr;
  int nVar_tmp_tmp;
  boolean_T nonDegenerateWset;
  mWConstr = workingset->nActiveConstr;
  nVar_tmp_tmp = workingset->nVar;
  nonDegenerateWset = true;
  if (mWConstr != 0) {
    double c;
    int i;
    int i1;
    int iAcol;
    int jBcol;
    int k;
    int kAcol;
    for (jBcol = 0; jBcol < mWConstr; jBcol++) {
      workspace[jBcol] = workingset->bwset[jBcol];
      workspace[jBcol + 5] = workingset->bwset[jBcol];
    }
    if (mWConstr != 0) {
      i = ((mWConstr - 1) << 2) + 1;
      for (iAcol = 1; iAcol <= i; iAcol += 4) {
        c = 0.0;
        i1 = (iAcol + nVar_tmp_tmp) - 1;
        for (jBcol = iAcol; jBcol <= i1; jBcol++) {
          c += workingset->ATwset[jBcol - 1] * xCurrent[jBcol - iAcol];
        }
        i1 = (iAcol - 1) >> 2;
        workspace[i1] += -c;
      }
    }
    if (mWConstr >= nVar_tmp_tmp) {
      int ar;
      qrmanager->usedPivoting = false;
      qrmanager->mrows = mWConstr;
      qrmanager->ncols = nVar_tmp_tmp;
      for (kAcol = 0; kAcol < nVar_tmp_tmp; kAcol++) {
        iAcol = kAcol << 2;
        for (jBcol = 0; jBcol < mWConstr; jBcol++) {
          qrmanager->QR[jBcol + iAcol] =
              workingset->ATwset[kAcol + (jBcol << 2)];
        }
        qrmanager->jpvt[kAcol] = kAcol + 1;
      }
      if (mWConstr <= nVar_tmp_tmp) {
        i = mWConstr;
      } else {
        i = nVar_tmp_tmp;
      }
      qrmanager->minRowCol = i;
      std::copy(&qrmanager->QR[0], &qrmanager->QR[20], &B[0]);
      qrmanager->tau[0] = 0.0;
      qrmanager->tau[1] = 0.0;
      qrmanager->tau[2] = 0.0;
      qrmanager->tau[3] = 0.0;
      if (i >= 1) {
        internal::reflapack::qrf(B, mWConstr, nVar_tmp_tmp, i, qrmanager->tau);
      }
      std::copy(&B[0], &B[20], &qrmanager->QR[0]);
      QRManager::computeQ_(qrmanager, mWConstr);
      std::copy(&workspace[0], &workspace[20], &B[0]);
      for (k = 0; k <= 5; k += 5) {
        i = k + 1;
        i1 = k + nVar_tmp_tmp;
        if (i <= i1) {
          std::memset(&workspace[i + -1], 0, ((i1 - i) + 1) * sizeof(double));
        }
      }
      jBcol = -1;
      for (k = 0; k <= 5; k += 5) {
        ar = -1;
        i = k + 1;
        i1 = k + nVar_tmp_tmp;
        for (int ic{i}; ic <= i1; ic++) {
          c = 0.0;
          for (iAcol = 0; iAcol < mWConstr; iAcol++) {
            c += qrmanager->Q[(iAcol + ar) + 1] * B[(iAcol + jBcol) + 1];
          }
          workspace[ic - 1] += c;
          ar += 4;
        }
        jBcol += 5;
      }
      for (ar = 0; ar < 2; ar++) {
        jBcol = 5 * ar - 1;
        for (k = nVar_tmp_tmp; k >= 1; k--) {
          kAcol = ((k - 1) << 2) - 1;
          i = k + jBcol;
          c = workspace[i];
          if (c != 0.0) {
            workspace[i] = c / qrmanager->QR[k + kAcol];
            for (int b_i{0}; b_i <= k - 2; b_i++) {
              i1 = (b_i + jBcol) + 1;
              workspace[i1] -= workspace[i] * qrmanager->QR[(b_i + kAcol) + 1];
            }
          }
        }
      }
    } else {
      int ar;
      int b_i;
      QRManager::factorQR(qrmanager, workingset->ATwset, nVar_tmp_tmp,
                          mWConstr);
      QRManager::computeQ_(qrmanager, qrmanager->minRowCol);
      for (ar = 0; ar < 2; ar++) {
        jBcol = 5 * ar;
        for (b_i = 0; b_i < mWConstr; b_i++) {
          iAcol = b_i << 2;
          kAcol = b_i + jBcol;
          c = workspace[kAcol];
          for (k = 0; k < b_i; k++) {
            c -= qrmanager->QR[k + iAcol] * workspace[k + jBcol];
          }
          workspace[kAcol] = c / qrmanager->QR[b_i + iAcol];
        }
      }
      std::copy(&workspace[0], &workspace[20], &B[0]);
      for (k = 0; k <= 5; k += 5) {
        i = k + 1;
        i1 = k + nVar_tmp_tmp;
        if (i <= i1) {
          std::memset(&workspace[i + -1], 0, ((i1 - i) + 1) * sizeof(double));
        }
      }
      jBcol = 0;
      for (k = 0; k <= 5; k += 5) {
        ar = -1;
        i = jBcol + 1;
        i1 = jBcol + mWConstr;
        for (b_i = i; b_i <= i1; b_i++) {
          iAcol = k + 1;
          kAcol = k + nVar_tmp_tmp;
          for (int ic{iAcol}; ic <= kAcol; ic++) {
            workspace[ic - 1] += B[b_i - 1] * qrmanager->Q[(ar + ic) - k];
          }
          ar += 4;
        }
        jBcol += 5;
      }
    }
    jBcol = 0;
    int exitg1;
    do {
      exitg1 = 0;
      if (jBcol <= nVar_tmp_tmp - 1) {
        if (std::isinf(workspace[jBcol]) || std::isnan(workspace[jBcol])) {
          nonDegenerateWset = false;
          exitg1 = 1;
        } else {
          c = workspace[jBcol + 5];
          if (std::isinf(c) || std::isnan(c)) {
            nonDegenerateWset = false;
            exitg1 = 1;
          } else {
            jBcol++;
          }
        }
      } else {
        double constrViolation_minnormX;
        iAcol = nVar_tmp_tmp - 1;
        for (k = 0; k <= iAcol; k++) {
          workspace[k] += xCurrent[k];
        }
        kAcol = workingset->sizes[3];
        if (workingset->probType == 2) {
          workingset->maxConstrWorkspace[0] = workingset->bineq;
          workingset->maxConstrWorkspace[0] =
              -workingset->maxConstrWorkspace[0];
          workingset->maxConstrWorkspace[0] +=
              (workingset->Aineq[0] * workspace[0] +
               workingset->Aineq[1] * workspace[1]) +
              workingset->Aineq[2] * workspace[2];
          workingset->maxConstrWorkspace[0] -= workspace[3];
          constrViolation_minnormX =
              std::fmax(0.0, workingset->maxConstrWorkspace[0]);
        } else {
          workingset->maxConstrWorkspace[0] = workingset->bineq;
          workingset->maxConstrWorkspace[0] =
              -workingset->maxConstrWorkspace[0];
          c = 0.0;
          i = workingset->nVar;
          for (jBcol = 1; jBcol <= i; jBcol++) {
            c += workingset->Aineq[jBcol - 1] * workspace[jBcol - 1];
          }
          workingset->maxConstrWorkspace[0] += c;
          constrViolation_minnormX =
              std::fmax(0.0, workingset->maxConstrWorkspace[0]);
        }
        if (workingset->sizes[3] > 0) {
          for (jBcol = 0; jBcol < kAcol; jBcol++) {
            iAcol = workingset->indexLB[jBcol] - 1;
            constrViolation_minnormX =
                std::fmax(constrViolation_minnormX,
                          -workspace[iAcol] - workingset->lb[iAcol]);
          }
        }
        kAcol = workingset->sizes[3];
        if (workingset->probType == 2) {
          workingset->maxConstrWorkspace[0] = workingset->bineq;
          workingset->maxConstrWorkspace[0] =
              -workingset->maxConstrWorkspace[0];
          workingset->maxConstrWorkspace[0] +=
              (workingset->Aineq[0] * workspace[5] +
               workingset->Aineq[1] * workspace[6]) +
              workingset->Aineq[2] * workspace[7];
          workingset->maxConstrWorkspace[0] -= workspace[8];
          c = std::fmax(0.0, workingset->maxConstrWorkspace[0]);
        } else {
          workingset->maxConstrWorkspace[0] = workingset->bineq;
          workingset->maxConstrWorkspace[0] =
              -workingset->maxConstrWorkspace[0];
          c = 0.0;
          i = workingset->nVar;
          for (jBcol = 1; jBcol <= i; jBcol++) {
            c += workingset->Aineq[jBcol - 1] * workspace[jBcol + 4];
          }
          workingset->maxConstrWorkspace[0] += c;
          c = std::fmax(0.0, workingset->maxConstrWorkspace[0]);
        }
        if (workingset->sizes[3] > 0) {
          for (jBcol = 0; jBcol < kAcol; jBcol++) {
            iAcol = workingset->indexLB[jBcol];
            c = std::fmax(c, -workspace[iAcol + 4] - workingset->lb[iAcol - 1]);
          }
        }
        if ((constrViolation_minnormX <= 2.2204460492503131E-16) ||
            (constrViolation_minnormX < c)) {
          if (0 <= nVar_tmp_tmp - 1) {
            std::copy(&workspace[0], &workspace[nVar_tmp_tmp], &xCurrent[0]);
          }
        } else if (0 <= nVar_tmp_tmp - 1) {
          std::copy(&workspace[5], &workspace[5 + nVar_tmp_tmp], &xCurrent[0]);
        }
        exitg1 = 1;
      }
    } while (exitg1 == 0);
  }
  return nonDegenerateWset;
}

//
// Arguments    : const double H[9]
//                const double f[3]
//                struct_T *solution
//                d_struct_T *memspace
//                f_struct_T *workingset
//                e_struct_T *qrmanager
//                c_struct_T *cholmanager
//                b_struct_T *objective
//                double options_ObjectiveLimit
//                double options_StepTolerance
//                int runTimeOptions_MaxIterations
//                double runTimeOptions_ConstrRelTolFactor
//                double runTimeOptions_ProbRelTolFactor
//                boolean_T runTimeOptions_RemainFeasible
// Return Type  : void
//
} // namespace initialize
static void iterate(const double H[9], const double f[3], struct_T *solution,
                    d_struct_T *memspace, f_struct_T *workingset,
                    e_struct_T *qrmanager, c_struct_T *cholmanager,
                    b_struct_T *objective, double options_ObjectiveLimit,
                    double options_StepTolerance,
                    int runTimeOptions_MaxIterations,
                    double runTimeOptions_ConstrRelTolFactor,
                    double runTimeOptions_ProbRelTolFactor,
                    boolean_T runTimeOptions_RemainFeasible)
{
  double c;
  double minLambda;
  double s;
  double temp_tmp;
  double tolDelta;
  int TYPE;
  int activeSetChangeID;
  int globalActiveConstrIdx;
  int idxRotGCol;
  int iyend;
  int k;
  int nVar_tmp_tmp;
  boolean_T newBlocking;
  boolean_T subProblemChanged;
  boolean_T updateFval;
  subProblemChanged = true;
  updateFval = true;
  activeSetChangeID = 0;
  TYPE = objective->objtype;
  tolDelta = 6.7434957617430445E-7;
  nVar_tmp_tmp = workingset->nVar;
  globalActiveConstrIdx = 0;
  Objective::computeGrad_StoreHx(objective, H, f, solution->xstar);
  solution->fstar = Objective::computeFval_ReuseHx(
      objective, memspace->workspace_double, f, solution->xstar);
  if (solution->iterations < runTimeOptions_MaxIterations) {
    solution->state = -5;
  } else {
    solution->state = 0;
  }
  for (k = 0; k < 5; k++) {
    solution->lambda[k] = 0.0;
  }
  int exitg1;
  do {
    exitg1 = 0;
    if (solution->state == -5) {
      int idx;
      int idxMinLambda;
      boolean_T guard1{false};
      boolean_T guard2{false};
      guard1 = false;
      guard2 = false;
      if (subProblemChanged) {
        switch (activeSetChangeID) {
        case 1:
          idxMinLambda = (workingset->nActiveConstr - 1) << 2;
          iyend = qrmanager->mrows;
          idxRotGCol = qrmanager->ncols + 1;
          if (iyend <= idxRotGCol) {
            idxRotGCol = iyend;
          }
          qrmanager->minRowCol = idxRotGCol;
          idxRotGCol = qrmanager->ncols << 2;
          if (qrmanager->mrows != 0) {
            iyend = idxRotGCol + qrmanager->mrows;
            if (idxRotGCol + 1 <= iyend) {
              std::memset(&qrmanager->QR[idxRotGCol], 0,
                          (iyend - idxRotGCol) * sizeof(double));
            }
            k = ((qrmanager->mrows - 1) << 2) + 1;
            for (idx = 1; idx <= k; idx += 4) {
              c = 0.0;
              iyend = (idx + qrmanager->mrows) - 1;
              for (int ia{idx}; ia <= iyend; ia++) {
                c += qrmanager->Q[ia - 1] *
                     workingset->ATwset[(idxMinLambda + ia) - idx];
              }
              iyend = idxRotGCol + ((idx - 1) >> 2);
              qrmanager->QR[iyend] += c;
            }
          }
          qrmanager->ncols++;
          qrmanager->jpvt[qrmanager->ncols - 1] = qrmanager->ncols;
          for (idx = qrmanager->mrows - 2; idx + 2 > qrmanager->ncols; idx--) {
            idxRotGCol = (qrmanager->ncols - 1) << 2;
            k = (idx + idxRotGCol) + 1;
            temp_tmp = qrmanager->QR[k];
            internal::blas::xrotg(&qrmanager->QR[idx + idxRotGCol], &temp_tmp,
                                  &c, &s);
            qrmanager->QR[k] = temp_tmp;
            iyend = idx << 2;
            idxRotGCol = qrmanager->mrows;
            if (qrmanager->mrows >= 1) {
              for (k = 0; k < idxRotGCol; k++) {
                idxMinLambda = iyend + k;
                minLambda = qrmanager->Q[idxMinLambda + 4];
                temp_tmp = qrmanager->Q[idxMinLambda];
                qrmanager->Q[idxMinLambda + 4] = c * minLambda - s * temp_tmp;
                qrmanager->Q[idxMinLambda] = c * temp_tmp + s * minLambda;
              }
            }
          }
          break;
        case -1:
          QRManager::deleteColMoveEnd(qrmanager, globalActiveConstrIdx);
          break;
        default:
          QRManager::factorQR(qrmanager, workingset->ATwset, nVar_tmp_tmp,
                              workingset->nActiveConstr);
          QRManager::computeQ_(qrmanager, qrmanager->mrows);
          break;
        }
        compute_deltax(H, solution, memspace, qrmanager, cholmanager,
                       objective);
        if (solution->state != -5) {
          exitg1 = 1;
        } else if ((internal::blas::xnrm2(nVar_tmp_tmp, solution->searchDir) <
                    options_StepTolerance) ||
                   (workingset->nActiveConstr >= nVar_tmp_tmp)) {
          guard2 = true;
        } else {
          updateFval = (TYPE == 5);
          if (updateFval || runTimeOptions_RemainFeasible) {
            feasibleratiotest(
                solution->xstar, solution->searchDir,
                memspace->workspace_double, workingset->nVar, workingset->Aineq,
                workingset->bineq, workingset->lb, workingset->indexLB,
                workingset->sizes, workingset->isActiveIdx,
                workingset->isActiveConstr, workingset->nWConstr, updateFval,
                &minLambda, &newBlocking, &iyend, &idxRotGCol);
          } else {
            ratiotest(solution->xstar, solution->searchDir,
                      memspace->workspace_double, workingset->nVar,
                      workingset->Aineq, workingset->bineq, workingset->lb,
                      workingset->indexLB, workingset->sizes,
                      workingset->isActiveIdx, workingset->isActiveConstr,
                      workingset->nWConstr, &tolDelta, &minLambda, &newBlocking,
                      &iyend, &idxRotGCol);
          }
          if (newBlocking) {
            switch (iyend) {
            case 3:
              workingset->nWConstr[2]++;
              workingset
                  ->isActiveConstr[(workingset->isActiveIdx[2] + idxRotGCol) -
                                   2] = true;
              workingset->nActiveConstr++;
              workingset->Wid[workingset->nActiveConstr - 1] = 3;
              workingset->Wlocalidx[workingset->nActiveConstr - 1] = idxRotGCol;
              iyend = (idxRotGCol - 1) << 2;
              idxRotGCol = (workingset->nActiveConstr - 1) << 2;
              k = workingset->nVar - 1;
              for (idx = 0; idx <= k; idx++) {
                workingset->ATwset[idxRotGCol + idx] =
                    workingset->Aineq[iyend + idx];
              }
              workingset->bwset[workingset->nActiveConstr - 1] =
                  workingset->bineq;
              break;
            case 4:
              WorkingSet::addBoundToActiveSetMatrix_(workingset, 4, idxRotGCol);
              break;
            default:
              WorkingSet::addBoundToActiveSetMatrix_(workingset, 5, idxRotGCol);
              break;
            }
            activeSetChangeID = 1;
          } else {
            if (objective->objtype == 5) {
              if (internal::blas::xnrm2(objective->nvar, solution->searchDir) >
                  100.0 * static_cast<double>(objective->nvar) *
                      1.4901161193847656E-8) {
                solution->state = 3;
              } else {
                solution->state = 4;
              }
            }
            subProblemChanged = false;
            if (workingset->nActiveConstr == 0) {
              solution->state = 1;
            }
          }
          if (!(minLambda == 0.0)) {
            iyend = nVar_tmp_tmp - 1;
            for (k = 0; k <= iyend; k++) {
              solution->xstar[k] += minLambda * solution->searchDir[k];
            }
          }
          Objective::computeGrad_StoreHx(objective, H, f, solution->xstar);
          updateFval = true;
          guard1 = true;
        }
      } else {
        if (0 <= nVar_tmp_tmp - 1) {
          std::memset(&solution->searchDir[0], 0,
                      nVar_tmp_tmp * sizeof(double));
        }
        guard2 = true;
      }
      if (guard2) {
        compute_lambda(memspace->workspace_double, solution, objective,
                       qrmanager);
        if ((solution->state != -7) ||
            (workingset->nActiveConstr > nVar_tmp_tmp)) {
          idxMinLambda = -1;
          minLambda = 0.0 * runTimeOptions_ProbRelTolFactor *
                      static_cast<double>(TYPE != 5);
          k = (workingset->nWConstr[0] + workingset->nWConstr[1]) + 1;
          iyend = workingset->nActiveConstr;
          for (idx = k; idx <= iyend; idx++) {
            temp_tmp = solution->lambda[idx - 1];
            if (temp_tmp < minLambda) {
              minLambda = temp_tmp;
              idxMinLambda = idx - 1;
            }
          }
          if (idxMinLambda + 1 == 0) {
            solution->state = 1;
          } else {
            activeSetChangeID = -1;
            globalActiveConstrIdx = idxMinLambda + 1;
            subProblemChanged = true;
            iyend = workingset->Wid[idxMinLambda] - 1;
            workingset->isActiveConstr
                [(workingset->isActiveIdx[workingset->Wid[idxMinLambda] - 1] +
                  workingset->Wlocalidx[idxMinLambda]) -
                 2] = false;
            workingset->Wid[idxMinLambda] =
                workingset->Wid[workingset->nActiveConstr - 1];
            workingset->Wlocalidx[idxMinLambda] =
                workingset->Wlocalidx[workingset->nActiveConstr - 1];
            k = workingset->nVar;
            for (idx = 0; idx < k; idx++) {
              workingset->ATwset[idx + (idxMinLambda << 2)] =
                  workingset
                      ->ATwset[idx + ((workingset->nActiveConstr - 1) << 2)];
            }
            workingset->bwset[idxMinLambda] =
                workingset->bwset[workingset->nActiveConstr - 1];
            workingset->nActiveConstr--;
            workingset->nWConstr[iyend]--;
            solution->lambda[idxMinLambda] = 0.0;
          }
        } else {
          idxMinLambda = workingset->nActiveConstr;
          activeSetChangeID = 0;
          globalActiveConstrIdx = workingset->nActiveConstr;
          subProblemChanged = true;
          iyend = workingset->nActiveConstr - 1;
          idxRotGCol = workingset->Wid[iyend] - 1;
          workingset->isActiveConstr[(workingset->isActiveIdx[idxRotGCol] +
                                      workingset->Wlocalidx[iyend]) -
                                     2] = false;
          workingset->nActiveConstr--;
          workingset->nWConstr[idxRotGCol]--;
          solution->lambda[idxMinLambda - 1] = 0.0;
        }
        updateFval = false;
        guard1 = true;
      }
      if (guard1) {
        solution->iterations++;
        iyend = objective->nvar - 1;
        if ((solution->iterations >= runTimeOptions_MaxIterations) &&
            ((solution->state != 1) || (objective->objtype == 5))) {
          solution->state = 0;
        }
        if (solution->iterations - solution->iterations / 50 * 50 == 0) {
          solution->maxConstr =
              WorkingSet::maxConstraintViolation(workingset, solution->xstar);
          minLambda = solution->maxConstr;
          if (objective->objtype == 5) {
            minLambda = solution->maxConstr - solution->xstar[iyend];
          }
          if (minLambda > 1.0E-8 * runTimeOptions_ConstrRelTolFactor) {
            if (0 <= iyend) {
              std::copy(&solution->xstar[0], &solution->xstar[iyend + 1],
                        &solution->searchDir[0]);
            }
            newBlocking = initialize::feasibleX0ForWorkingSet(
                memspace->workspace_double, solution->searchDir, workingset,
                qrmanager);
            if ((!newBlocking) && (solution->state != 0)) {
              solution->state = -2;
            }
            activeSetChangeID = 0;
            minLambda = WorkingSet::maxConstraintViolation(workingset,
                                                           solution->searchDir);
            if (minLambda < solution->maxConstr) {
              if (0 <= iyend) {
                std::copy(&solution->searchDir[0],
                          &solution->searchDir[iyend + 1], &solution->xstar[0]);
              }
              solution->maxConstr = minLambda;
            }
          }
        }
        if (updateFval && (options_ObjectiveLimit > rtMinusInf)) {
          solution->fstar = Objective::computeFval_ReuseHx(
              objective, memspace->workspace_double, f, solution->xstar);
          if ((solution->fstar < options_ObjectiveLimit) &&
              ((solution->state != 0) || (objective->objtype != 5))) {
            solution->state = 2;
          }
        }
      }
    } else {
      if (!updateFval) {
        solution->fstar = Objective::computeFval_ReuseHx(
            objective, memspace->workspace_double, f, solution->xstar);
      }
      exitg1 = 1;
    }
  } while (exitg1 == 0);
}

//
// Arguments    : struct_T *solution
//                const b_struct_T *objective
//                int workingset_nVar
//                const double workingset_ATwset[20]
//                int workingset_nActiveConstr
//                double workspace[20]
// Return Type  : void
//
namespace parseoutput {
static void
computeFirstOrderOpt(struct_T *solution, const b_struct_T *objective,
                     int workingset_nVar, const double workingset_ATwset[20],
                     int workingset_nActiveConstr, double workspace[20])
{
  double smax;
  int ix;
  int k;
  if (0 <= workingset_nVar - 1) {
    std::copy(&objective->grad[0], &objective->grad[workingset_nVar],
              &workspace[0]);
  }
  if (workingset_nActiveConstr != 0) {
    ix = 0;
    k = ((workingset_nActiveConstr - 1) << 2) + 1;
    for (int iac{1}; iac <= k; iac += 4) {
      int i;
      i = (iac + workingset_nVar) - 1;
      for (int ia{iac}; ia <= i; ia++) {
        int i1;
        i1 = ia - iac;
        workspace[i1] += workingset_ATwset[ia - 1] * solution->lambda[ix];
      }
      ix++;
    }
  }
  ix = 1;
  smax = std::abs(workspace[0]);
  for (k = 2; k <= workingset_nVar; k++) {
    double s;
    s = std::abs(workspace[k - 1]);
    if (s > smax) {
      ix = k;
      smax = s;
    }
  }
  solution->firstorderopt = std::abs(workspace[ix - 1]);
}

//
// Arguments    : const double solution_xstar[4]
//                const double solution_searchDir[4]
//                double workspace[20]
//                int workingset_nVar
//                const double workingset_Aineq[4]
//                double workingset_bineq
//                const double workingset_lb[4]
//                const int workingset_indexLB[4]
//                const int workingset_sizes[5]
//                const int workingset_isActiveIdx[6]
//                const boolean_T workingset_isActiveConstr[5]
//                const int workingset_nWConstr[5]
//                double *toldelta
//                double *alpha
//                boolean_T *newBlocking
//                int *constrType
//                int *constrIdx
// Return Type  : void
//
} // namespace parseoutput
static void
ratiotest(const double solution_xstar[4], const double solution_searchDir[4],
          double workspace[20], int workingset_nVar,
          const double workingset_Aineq[4], double workingset_bineq,
          const double workingset_lb[4], const int workingset_indexLB[4],
          const int workingset_sizes[5], const int workingset_isActiveIdx[6],
          const boolean_T workingset_isActiveConstr[5],
          const int workingset_nWConstr[5], double *toldelta, double *alpha,
          boolean_T *newBlocking, int *constrType, int *constrIdx)
{
  double b_c;
  double c;
  double denomTol;
  double p_max;
  double phaseOneCorrectionP;
  int ia;
  *alpha = 1.0E+30;
  *newBlocking = false;
  *constrType = 0;
  *constrIdx = 0;
  p_max = 0.0;
  denomTol = 2.2204460492503131E-13 *
             internal::blas::xnrm2(workingset_nVar, solution_searchDir);
  if (workingset_nWConstr[2] < 1) {
    workspace[0] = workingset_bineq;
    workspace[0] = -workspace[0];
    b_c = 0.0;
    workspace[5] = 0.0;
    c = 0.0;
    for (ia = 1; ia <= workingset_nVar; ia++) {
      phaseOneCorrectionP = workingset_Aineq[ia - 1];
      b_c += phaseOneCorrectionP * solution_xstar[ia - 1];
      c += phaseOneCorrectionP * solution_searchDir[ia - 1];
    }
    workspace[0] += b_c;
    workspace[5] += c;
    if ((workspace[5] > denomTol) &&
        (!workingset_isActiveConstr[workingset_isActiveIdx[2] - 1])) {
      b_c = std::fmin(std::abs(workspace[0] - *toldelta),
                      (1.0E-8 - workspace[0]) + *toldelta) /
            workspace[5];
      if ((b_c <= 1.0E+30) && (std::abs(workspace[5]) > 0.0)) {
        *alpha = b_c;
        *constrType = 3;
        *constrIdx = 1;
        *newBlocking = true;
      }
      b_c = std::fmin(std::abs(workspace[0]), 1.0E-8 - workspace[0]) /
            workspace[5];
      if (b_c < *alpha) {
        *alpha = b_c;
        *constrType = 3;
        *constrIdx = 1;
        *newBlocking = true;
        p_max = std::abs(workspace[5]);
      }
    }
  }
  if (workingset_nWConstr[3] < workingset_sizes[3]) {
    double ratio_tmp;
    c = 0.0 * solution_xstar[workingset_nVar - 1];
    phaseOneCorrectionP = 0.0 * solution_searchDir[workingset_nVar - 1];
    ia = workingset_sizes[3];
    for (int idx{0}; idx <= ia - 2; idx++) {
      double pk_corrected;
      int i;
      i = workingset_indexLB[idx];
      pk_corrected = -solution_searchDir[i - 1] - phaseOneCorrectionP;
      if ((pk_corrected > denomTol) &&
          (!workingset_isActiveConstr[(workingset_isActiveIdx[3] + idx) - 1])) {
        ratio_tmp = -solution_xstar[i - 1] - workingset_lb[i - 1];
        b_c = (ratio_tmp - *toldelta) - c;
        b_c = std::fmin(std::abs(b_c), 1.0E-8 - b_c) / pk_corrected;
        if ((b_c <= *alpha) && (std::abs(pk_corrected) > p_max)) {
          *alpha = b_c;
          *constrType = 4;
          *constrIdx = idx + 1;
          *newBlocking = true;
        }
        b_c = ratio_tmp - c;
        b_c = std::fmin(std::abs(b_c), 1.0E-8 - b_c) / pk_corrected;
        if (b_c < *alpha) {
          *alpha = b_c;
          *constrType = 4;
          *constrIdx = idx + 1;
          *newBlocking = true;
          p_max = std::abs(pk_corrected);
        }
      }
    }
    ia = workingset_indexLB[workingset_sizes[3] - 1] - 1;
    phaseOneCorrectionP = solution_searchDir[ia];
    if ((-phaseOneCorrectionP > denomTol) &&
        (!workingset_isActiveConstr
             [(workingset_isActiveIdx[3] + workingset_sizes[3]) - 2])) {
      ratio_tmp = -solution_xstar[ia] - workingset_lb[ia];
      b_c = ratio_tmp - *toldelta;
      b_c = std::fmin(std::abs(b_c), 1.0E-8 - b_c) / -phaseOneCorrectionP;
      if ((b_c <= *alpha) && (std::abs(phaseOneCorrectionP) > p_max)) {
        *alpha = b_c;
        *constrType = 4;
        *constrIdx = workingset_sizes[3];
        *newBlocking = true;
      }
      b_c = std::fmin(std::abs(ratio_tmp), 1.0E-8 - ratio_tmp) /
            -phaseOneCorrectionP;
      if (b_c < *alpha) {
        *alpha = b_c;
        *constrType = 4;
        *constrIdx = workingset_sizes[3];
        *newBlocking = true;
        p_max = std::abs(solution_searchDir[ia]);
      }
    }
  }
  *toldelta += 6.608625846508183E-7;
  if (p_max > 0.0) {
    *alpha = std::fmax(*alpha, 6.608625846508183E-7 / p_max);
  }
  if ((*newBlocking) && (*alpha > 1.0)) {
    *newBlocking = false;
  }
  *alpha = std::fmin(*alpha, 1.0);
}

//
// Arguments    : int x[5]
//                int xLen
//                int workspace[5]
//                int xMin
//                int xMax
// Return Type  : void
//
} // namespace qpactiveset
namespace utils {
static void countsort(int x[5], int xLen, int workspace[5], int xMin, int xMax)
{
  if ((xLen > 1) && (xMax > xMin)) {
    int idx;
    int idxEnd;
    int idxStart;
    int maxOffset;
    idxStart = xMax - xMin;
    if (0 <= idxStart) {
      std::memset(&workspace[0], 0, (idxStart + 1) * sizeof(int));
    }
    maxOffset = idxStart - 1;
    for (idx = 0; idx < xLen; idx++) {
      idxStart = x[idx] - xMin;
      workspace[idxStart]++;
    }
    for (idx = 2; idx <= maxOffset + 2; idx++) {
      workspace[idx - 1] += workspace[idx - 2];
    }
    idxStart = 1;
    idxEnd = workspace[0];
    for (idx = 0; idx <= maxOffset; idx++) {
      for (int idxFill{idxStart}; idxFill <= idxEnd; idxFill++) {
        x[idxFill - 1] = idx + xMin;
      }
      idxStart = workspace[idx] + 1;
      idxEnd = workspace[idx + 1];
    }
    for (idx = idxStart; idx <= idxEnd; idx++) {
      x[idx - 1] = xMax;
    }
  }
}

//
// Arguments    : double u0
//                double u1
// Return Type  : double
//
} // namespace utils
} // namespace coder
} // namespace optim
} // namespace coder
static double rt_hypotd_snf(double u0, double u1)
{
  double a;
  double y;
  a = std::abs(u0);
  y = std::abs(u1);
  if (a < y) {
    a /= y;
    y *= std::sqrt(a * a + 1.0);
  } else if (a > y) {
    y /= a;
    y = a * std::sqrt(y * y + 1.0);
  } else if (!std::isnan(y)) {
    y = a * 1.4142135623730951;
  }
  return y;
}

//
// Arguments    : const double H[9]
//                const double f[3]
//                const double A[3]
//                double b
//                const double lb[3]
//                const double x0[3]
//                double x[3]
//                double *fval
//                double *exitflag
// Return Type  : void
//
void fun_quadprog(const double H[9], const double f[3], const double A[3],
                  double b, const double lb[3], const double x0[3], double x[3],
                  double *fval, double *exitflag)
{
  b_struct_T QPObjective;
  c_struct_T CholRegManager;
  d_struct_T memspace;
  e_struct_T QRManager;
  f_struct_T WorkingSet;
  struct_T solution;
  double H_infnrm;
  double f_infnrm;
  double tol;
  int i;
  int idx;
  int mLB;
  signed char obj_tmp[5];
  signed char b_i;
  solution.fstar = 0.0;
  solution.firstorderopt = 0.0;
  for (i = 0; i < 5; i++) {
    solution.lambda[i] = 0.0;
  }
  solution.state = 0;
  solution.maxConstr = 0.0;
  solution.iterations = 0;
  solution.searchDir[0] = 0.0;
  solution.searchDir[1] = 0.0;
  solution.searchDir[2] = 0.0;
  solution.searchDir[3] = 0.0;
  solution.xstar[0] = x0[0];
  solution.xstar[1] = x0[1];
  solution.xstar[2] = x0[2];
  CholRegManager.ldm = 4;
  CholRegManager.ndims = 0;
  CholRegManager.info = 0;
  CholRegManager.ConvexCheck = true;
  CholRegManager.regTol_ = 0.0;
  CholRegManager.scaleFactor = 100.0;
  WorkingSet.nVar = 3;
  WorkingSet.nVarOrig = 3;
  WorkingSet.nVarMax = 4;
  WorkingSet.ldA = 4;
  WorkingSet.ub[0] = 0.0;
  WorkingSet.ub[1] = 0.0;
  WorkingSet.ub[2] = 0.0;
  WorkingSet.Aineq[3] = 0.0;
  WorkingSet.lb[3] = 0.0;
  WorkingSet.ub[3] = 0.0;
  WorkingSet.mEqRemoved = 0;
  std::memset(&WorkingSet.ATwset[0], 0, 20U * sizeof(double));
  WorkingSet.nActiveConstr = 0;
  for (i = 0; i < 5; i++) {
    WorkingSet.bwset[i] = 0.0;
    WorkingSet.maxConstrWorkspace[i] = 0.0;
    WorkingSet.isActiveConstr[i] = false;
    WorkingSet.Wid[i] = 0;
    WorkingSet.Wlocalidx[i] = 0;
    WorkingSet.nWConstr[i] = 0;
  }
  WorkingSet.probType = 3;
  WorkingSet.SLACK0 = 1.0E-5;
  WorkingSet.indexLB[0] = 0;
  WorkingSet.indexLB[1] = 0;
  WorkingSet.indexLB[2] = 0;
  WorkingSet.indexLB[3] = 0;
  mLB = 1;
  if ((!std::isinf(lb[0])) && (!std::isnan(lb[0]))) {
    mLB = 2;
    WorkingSet.indexLB[0] = 1;
  }
  if ((!std::isinf(lb[1])) && (!std::isnan(lb[1]))) {
    mLB++;
    WorkingSet.indexLB[mLB - 2] = 2;
  }
  if ((!std::isinf(lb[2])) && (!std::isnan(lb[2]))) {
    mLB++;
    WorkingSet.indexLB[mLB - 2] = 3;
  }
  WorkingSet.indexUB[0] = 0;
  WorkingSet.indexFixed[0] = 0;
  WorkingSet.indexUB[1] = 0;
  WorkingSet.indexFixed[1] = 0;
  WorkingSet.indexUB[2] = 0;
  WorkingSet.indexFixed[2] = 0;
  WorkingSet.indexUB[3] = 0;
  WorkingSet.indexFixed[3] = 0;
  WorkingSet.bineq = b;
  WorkingSet.mConstr = mLB;
  WorkingSet.mConstrOrig = mLB;
  WorkingSet.mConstrMax = 5;
  obj_tmp[0] = 0;
  obj_tmp[1] = 0;
  obj_tmp[2] = 1;
  obj_tmp[3] = static_cast<signed char>(mLB - 1);
  obj_tmp[4] = 0;
  for (i = 0; i < 5; i++) {
    b_i = obj_tmp[i];
    WorkingSet.sizes[i] = b_i;
    WorkingSet.sizesNormal[i] = b_i;
  }
  obj_tmp[0] = 0;
  obj_tmp[1] = 0;
  obj_tmp[2] = 1;
  obj_tmp[3] = static_cast<signed char>(mLB);
  obj_tmp[4] = 0;
  WorkingSet.sizesRegPhaseOne[0] = 0;
  WorkingSet.sizesRegPhaseOne[1] = 0;
  WorkingSet.sizesRegPhaseOne[2] = 1;
  WorkingSet.sizesRegPhaseOne[3] = mLB + 1;
  WorkingSet.sizesRegPhaseOne[4] = 0;
  WorkingSet.isActiveIdxRegPhaseOne[0] = 1;
  WorkingSet.isActiveIdxRegPhaseOne[1] = 0;
  WorkingSet.isActiveIdxRegPhaseOne[2] = 0;
  WorkingSet.isActiveIdxRegPhaseOne[3] = 1;
  WorkingSet.isActiveIdxRegPhaseOne[4] = mLB - 1;
  WorkingSet.isActiveIdxRegPhaseOne[5] = 0;
  for (i = 0; i < 5; i++) {
    b_i = obj_tmp[i];
    WorkingSet.sizesPhaseOne[i] = b_i;
    WorkingSet.sizesRegularized[i] = b_i;
    WorkingSet.isActiveIdxRegPhaseOne[i + 1] +=
        WorkingSet.isActiveIdxRegPhaseOne[i];
  }
  for (i = 0; i < 6; i++) {
    idx = WorkingSet.isActiveIdxRegPhaseOne[i];
    WorkingSet.isActiveIdx[i] = idx;
    WorkingSet.isActiveIdxNormal[i] = idx;
  }
  WorkingSet.isActiveIdxRegPhaseOne[0] = 1;
  WorkingSet.isActiveIdxRegPhaseOne[1] = 0;
  WorkingSet.isActiveIdxRegPhaseOne[2] = 0;
  WorkingSet.isActiveIdxRegPhaseOne[3] = 1;
  WorkingSet.isActiveIdxRegPhaseOne[4] = mLB;
  WorkingSet.isActiveIdxRegPhaseOne[5] = 0;
  for (i = 0; i < 5; i++) {
    WorkingSet.isActiveIdxRegPhaseOne[i + 1] +=
        WorkingSet.isActiveIdxRegPhaseOne[i];
  }
  for (i = 0; i < 6; i++) {
    idx = WorkingSet.isActiveIdxRegPhaseOne[i];
    WorkingSet.isActiveIdxPhaseOne[i] = idx;
    WorkingSet.isActiveIdxRegularized[i] = idx;
  }
  WorkingSet.isActiveIdxRegPhaseOne[0] = 1;
  WorkingSet.isActiveIdxRegPhaseOne[1] = 0;
  WorkingSet.isActiveIdxRegPhaseOne[2] = 0;
  WorkingSet.isActiveIdxRegPhaseOne[3] = 1;
  WorkingSet.isActiveIdxRegPhaseOne[4] = mLB + 1;
  WorkingSet.isActiveIdxRegPhaseOne[5] = 0;
  for (i = 0; i < 5; i++) {
    WorkingSet.isActiveIdxRegPhaseOne[i + 1] +=
        WorkingSet.isActiveIdxRegPhaseOne[i];
  }
  WorkingSet.Aineq[0] = A[0];
  WorkingSet.lb[0] = -lb[0];
  WorkingSet.Aineq[1] = A[1];
  WorkingSet.lb[1] = -lb[1];
  WorkingSet.Aineq[2] = A[2];
  WorkingSet.lb[2] = -lb[2];
  coder::optim::coder::qpactiveset::WorkingSet::setProblemType(&WorkingSet, 3);
  i = WorkingSet.isActiveIdx[2];
  for (idx = i; idx < 6; idx++) {
    WorkingSet.isActiveConstr[idx - 1] = false;
  }
  WorkingSet.nWConstr[0] = 0;
  WorkingSet.nWConstr[1] = 0;
  WorkingSet.nWConstr[2] = 0;
  WorkingSet.nWConstr[3] = 0;
  WorkingSet.nWConstr[4] = 0;
  WorkingSet.nActiveConstr = 0;
  WorkingSet.SLACK0 = 0.0;
  tol = std::fmax(
      1.0, (std::abs(WorkingSet.Aineq[0]) + std::abs(WorkingSet.Aineq[1])) +
               std::abs(WorkingSet.Aineq[2]));
  H_infnrm = 0.0;
  f_infnrm = 0.0;
  for (i = 0; i < 3; i++) {
    H_infnrm =
        std::fmax(H_infnrm, (std::abs(H[3 * i]) + std::abs(H[3 * i + 1])) +
                                std::abs(H[3 * i + 2]));
    f_infnrm = std::fmax(f_infnrm, std::abs(f[i]));
  }
  coder::optim::coder::qpactiveset::driver(
      H, f, &solution, &memspace, &WorkingSet, &CholRegManager, 10 * (mLB + 3),
      tol, std::fmax(std::fmax(tol, f_infnrm), H_infnrm), &QRManager,
      &QPObjective);
  x[0] = solution.xstar[0];
  x[1] = solution.xstar[1];
  x[2] = solution.xstar[2];
  if (solution.state > 0) {
    *fval = solution.fstar;
  } else {
    *fval = coder::optim::coder::qpactiveset::Objective::computeFval(
        &QPObjective, memspace.workspace_double, H, f, solution.xstar);
  }
  switch (solution.state) {
  case 2:
    solution.state = -3;
    break;
  case -3:
    solution.state = -2;
    break;
  case 4:
    solution.state = -2;
    break;
  }
  *exitflag = solution.state;
  if ((solution.state != -2) && (solution.state <= 0)) {
    solution.maxConstr =
        coder::optim::coder::qpactiveset::WorkingSet::maxConstraintViolation(
            &WorkingSet, solution.xstar);
    if (solution.maxConstr <= 1.0E-8 * tol) {
      switch (QPObjective.objtype) {
      case 5:
        break;
      case 3:
        coder::optim::coder::qpactiveset::Objective::b_linearForm_(
            QPObjective.hasLinear, QPObjective.nvar, QPObjective.grad, H, f,
            solution.xstar);
        break;
      default:
        coder::optim::coder::qpactiveset::Objective::b_linearForm_(
            QPObjective.hasLinear, QPObjective.nvar, QPObjective.grad, H, f,
            solution.xstar);
        break;
      }
    }
  }
}

//
// Arguments    : void
// Return Type  : void
//
void fun_quadprog_initialize()
{
}

//
// Arguments    : void
// Return Type  : void
//
void fun_quadprog_terminate()
{
  // (no terminate code required)
}

//
// File trailer for fun_quadprog.cpp
//
// [EOF]
//
