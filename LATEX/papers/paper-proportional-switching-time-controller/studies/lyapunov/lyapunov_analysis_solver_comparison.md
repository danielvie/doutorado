# Fresh Python, MATLAB, and Julia optimization comparison

All three solve the same trace-normalized common-P SDP. Python and MATLAB reconstruct the physical model independently. Julia imports the Python endpoint matrices.

| Implementation | Status | eta | min eig(P) | min eig(Q0) | min eig(Q1) | norm-rate bound |
|---|---|---:|---:|---:|---:|---:|
| Python | optimal | 2.911904324165e-04 | 4.987943287081e-03 | 2.911904324258e-04 | 2.911904411059e-04 | 0.999938954110 |
| MATLAB | Solved | 2.911904324328e-04 | 4.987943412695e-03 | 2.911904324328e-04 | 2.911904329125e-04 | 0.999938954110 |
| Julia | OPTIMAL | 2.911904314939e-04 | 4.987946970265e-03 | 2.911904317037e-04 | 2.911956095952e-04 | 0.999938954110 |

## Python: P

```
[[ 0.608769892518 -0.013731103754  0.027354204688]
 [-0.013731103754  2.384502299003  0.033888822562]
 [ 0.027354204688  0.033888822562  0.006727808479]]
```

## MATLAB: P

```
[[ 0.608769892369 -0.013731103815  0.027354206519]
 [-0.013731103815  2.384502298788  0.033888824996]
 [ 0.027354206519  0.033888824996  0.006727808843]]
```

## Julia: P

```
[[ 0.608769893783 -0.013731102957  0.027354173601]
 [-0.013731102957  2.384502297758  0.033888792565]
 [ 0.027354173601  0.033888792565  0.006727808459]]
```

## Pairwise differences

Relative differences use the first implementation in each pair as denominator. P uses the Frobenius norm.

| Pair | Relative P difference | Relative eta difference | Absolute rate-bound difference |
|---|---:|---:|---:|
| Python / MATLAB | 1.759334e-09 | 5.603633e-11 | 5.218048e-15 |
| Python / Julia | 2.483109e-08 | 3.168523e-09 | 9.758860e-14 |
| MATLAB / Julia | 2.655998e-08 | 3.224560e-09 | 1.028067e-13 |

All P and endpoint residual eigenvalues are positive. Differences are numerical, not a different stability conclusion. No runtime benchmark was performed. The guarantee remains for the conditioned linearized model, not global nonlinear stability.
