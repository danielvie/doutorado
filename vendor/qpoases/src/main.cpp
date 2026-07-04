#include "qpOASES.hpp"
#include <iostream>

int main(int argc, char const *argv[]) {
  USING_NAMESPACE_QPOASES

  const int nV = 2;
  const int nC = 3;

  real_t H[nV * nV] = {1, -1, -1, 2};
  real_t f[nV] = {-2, -6};
  real_t A[nV * nC] = {1, 1, -1, 2, 2, 1};
  real_t lb[nV] = {-1e20, -1e20};
  real_t ub[nV] = {1e20, 1e20};
  real_t lbA[nC] = {-1e20, -1e20, -1e20};
  real_t ubA[nC] = {2, 2, 3};

  QProblem example(nV, nC);

  Options options;
  options.printLevel = qpOASES::PL_NONE;
  // options.printLevel = qpOASES::PL_LOW;
  example.setOptions(options);

  // initialize QP
  int_t nWSR = 10; // maximum number of working set recalculations
  // example.init(H, f, A, lb, ub, lbA, ubA, nWSR);

  // solve the QP
  real_t xOpt[nV];
  // example.getPrimalSolution(xOpt);

  // print the solution
  std::cout << "Solution:\n";
  for (int i = 0; i < nV; ++i) {
    std::cout << "x[" << i << "] = " << xOpt[i] << std::endl;
  }

  return 0;
}
