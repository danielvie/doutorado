# Stability proof for the signal-conditioned cycle map

## Scope

This note reconstructs the stability argument in `article.tex`, Section 3, and ties each step to a runnable MATLAB check. The plant-to-matrix derivation is worked out separately in [`deriving-a0-a1.html`](deriving-a0-a1.html). It covers three cases:

1. `beta = 0`, the nominal schedule with no timing correction;
2. `beta = 1`, the raw closed-loop timing correction;
3. `beta in [0, 1]`, including a state-dependent or time-varying sequence of conditioning factors.

The first two cases are the endpoints of one matrix segment. The third proof works because both endpoints contract in the same quadratic norm.

Each script embeds the required endpoint matrix and solves its own semidefinite program with YALMIP and SeDuMi. Nothing is loaded from `results/paper_results.mat`, and the scripts do not call another project file. They then verify the optimized matrix with ordinary MATLAB operations.

This isolation has one cost. If the paper's generated linear model changes, the embedded matrices must be updated manually.

## 1. One-cycle linearization

Let `e_k` be the state error at the start of cycle `k`. The paper linearizes the exact switched-affine cycle map in the independent switching-instant offsets `delta_tau_k`:

\[
e_{k+1}=\Phi e_k+\Gamma_\tau\delta\tau_k
+\mathcal O\!\left(\left\|[e_k^\mathsf T\ \delta\tau_k^\mathsf T]\right\|^2\right).
\]

Here:

- \(\Phi\) is the Jacobian with respect to the cycle-start state;
- \(\Gamma_\tau\) is the Jacobian with respect to the interior switching instants;
- the switching offsets preserve the fixed cycle period because their dwell changes sum to zero.

The raw feedback law is

\[
\delta\tau_k^{\mathrm{raw}}=-K e_k,
\]

which gives the raw closed-loop matrix

\[
A_{\mathrm{cl}}=\Phi-\Gamma_\tau K.
\]

## 2. What signal conditioning changes

The conditioner scales the whole raw offset vector by one scalar:

\[
\delta\tau_k^{\mathrm{app}}=\beta_k\delta\tau_k^{\mathrm{raw}},
\qquad 0<\beta_k\le 1
\]

under the paper's strict nominal dwell-margin assumption. The closed interval \([0,1]\) is used for the stability certificate. Its \(\beta=0\) endpoint represents the correction being fully switched off and is the limiting worst case. With a strict positive dwell margin and finite raw action, the stated conditioner does not actually return zero.

Substitution into the linearized model gives

\[
\begin{aligned}
e_{k+1}
&=\left(\Phi-\beta_k\Gamma_\tau K\right)e_k,\\
A(\beta)
&=(1-\beta)\Phi+\beta A_{\mathrm{cl}}.
\end{aligned}
\]

Uniform scaling matters. It restricts every conditioned matrix to the line segment between \(\Phi\) and \(A_{\mathrm{cl}}\).

The implementation works in normalized coordinates

\[
z=S_x^{-1}e,
\qquad
v=\delta\tau/t_s.
\]

The scripts embed these normalized endpoint matrices at 17-digit precision:

\[
A_0=S_x^{-1}\Phi S_x,
\]

\[
B=S_x^{-1}\Gamma_\tau t_s,
\qquad
A_1=A_0-BK_n.
\]

Similarity preserves eigenvalues and stability, so proving stability in `z` coordinates proves it in the physical error coordinates.

## 3. Common quadratic Lyapunov function

Use

\[
V(z)=z^\mathsf T Pz,
\qquad P=P^\mathsf T>0.
\]

For a fixed matrix \(A\), one step changes `V` by

\[
\begin{aligned}
V(z_{k+1})-V(z_k)
&=z_k^\mathsf T(A^\mathsf TPA-P)z_k\\
&=-z_k^\mathsf TQz_k,
\end{aligned}
\]

where

\[
Q=P-A^\mathsf TPA.
\]

If both \(P>0\) and \(Q>0\), then \(V\) decreases for every nonzero state. This proves asymptotic stability. The strict matrix inequalities also give exponential stability in finite-dimensional discrete time.

The induced `P`-norm is

\[
\|A\|_P
=\max_{z\ne0}\frac{\|Az\|_P}{\|z\|_P}
=\sqrt{\lambda_{\max}(A^\mathsf TPA,P)}.
\]

If `R = chol(P)`, so \(P=R^\mathsf TR\), MATLAB can compute the same quantity as

```matlab
q = norm(R * A / R, 2);
```

A value `q < 1` means

\[
\|z_{k+1}\|_P\le q\|z_k\|_P.
\]

## 4. Optimization problem

The scale of a Lyapunov matrix is arbitrary. If `P` works, then any positive multiple of `P` also works. Each script removes this ambiguity with

\[
\operatorname{trace}(P)=1.
\]

For one endpoint \(A_i\), the decision variables are the symmetric matrix \(P\) and scalar \(t\). The SDP is

\[
\begin{aligned}
\underset{P,t}{\operatorname{maximize}}\quad & t\\
\text{subject to}\quad
&P\succeq \epsilon I,\\
&\operatorname{trace}(P)=1,\\
&P-A_i^\mathsf TPA_i\succeq tI,\\
&t\ge0.
\end{aligned}
\]

The scripts use \(\epsilon=10^{-8}\). If the optimizer returns \(t>0\), the Lyapunov decrease is strict. The interval script imposes the decrease constraint for both \(A_0\) and \(A_1\) using the same `P` and `t`.

The objective maximizes the smallest Euclidean eigenvalue of the decrease matrices under the chosen trace normalization. It does not directly minimize the induced `P`-norm. After optimization, each script computes that norm separately.

## 5. Proof for beta = 0

At \(\beta=0\),

\[
A(0)=A_0.
\]

The script `prove_beta_0.m` optimizes `P` subject to

\[
P>0,
\qquad
P-A_0^\mathsf TPA_0>0.
\]

It then verifies those inequalities and checks \(\|A_0\|_P<1\) without using YALMIP. The standalone optimization currently gives approximately

\[
t=9.72035\times10^{-5},
\qquad
\rho(A_0)=0.999850033,
\qquad
\|A_0\|_P=0.999938954.
\]

This endpoint is slow but strictly stable. For the exact switched-affine plant with the fixed nominal schedule, the cycle error map is affine with constant Jacobian \(\Phi\). Subtracting its fixed point gives `e_{k+1} = Phi e_k` exactly. The \(\beta=0\) result is therefore not restricted to a first-order approximation while the mode sequence and nominal durations stay fixed.

## 6. Proof for beta = 1

At \(\beta=1\),

\[
A(1)=A_1=A_{\mathrm{cl}}.
\]

The script `prove_beta_1.m` optimizes a separate `P` subject to

\[
P>0,
\qquad
P-A_1^\mathsf TPA_1>0.
\]

It then verifies those inequalities and checks \(\|A_1\|_P<1\). The standalone optimization currently gives approximately

\[
t=0.278703,
\qquad
\rho(A_1)=0.568151350,
\qquad
\|A_1\|_P=0.569430601.
\]

The spectral radius shows that the linearized closed loop is Schur. This endpoint-specific `P` cannot be used for the interval proof unless it also contracts \(A_0\). The interval script therefore computes a different, common `P`.

There is also a local nonlinear result. The nominal dwell vector has strict margin above the minimum dwell. Since the raw timing action is zero at the orbit, continuity gives a neighborhood where it remains feasible and the conditioner stays inactive, with \(\beta=1\). The exact closed-loop cycle map has Jacobian \(A_1\) at the orbit. Because \(A_1\) is Schur, the exact cycle map locally exponentially stabilizes that orbit.

## 7. Proof for every beta in [0, 1]

The script `prove_beta_interval.m` solves one optimization with both endpoint constraints:

\[
P-A_0^\mathsf TPA_0\succeq tI,
\qquad
P-A_1^\mathsf TPA_1\succeq tI.
\]

For the resulting common `P`, let

\[
q_0=\|A_0\|_P<1,
\qquad
q_1=\|A_1\|_P<1.
\]

For any \(\beta\in[0,1]\), homogeneity and the triangle inequality for the induced norm give

\[
\begin{aligned}
\|A(\beta)\|_P
&=\|(1-\beta)A_0+\beta A_1\|_P\\
&\le(1-\beta)\|A_0\|_P+\beta\|A_1\|_P\\
&=(1-\beta)q_0+\beta q_1\\
&\le\max(q_0,q_1)=q<1.
\end{aligned}
\]

This is an analytic proof for the whole interval. A grid sweep over `beta` would only provide samples and is not needed.

The same bound applies at every cycle even when \(\beta_k\) changes with the state:

\[
\|z_{k+1}\|_P
\le q\|z_k\|_P.
\]

Repeated application gives

\[
\|z_k\|_P
\le q^k\|z_0\|_P.
\]

Therefore the conditioned linearized family is uniformly exponentially stable for every sequence \(\{\beta_k\}\subset[0,1]\). The current certificate has

\[
q=0.999938942.
\]

The open-loop endpoint sets this worst-case bound.

## 8. What the numerical scripts establish

Each script:

1. defines its endpoint matrix or matrices locally;
2. declares `P` and `t` as YALMIP decision variables;
3. solves the SDP with SeDuMi;
4. converts the solution to an ordinary numeric matrix;
5. independently checks positive definiteness and the induced `P`-norm.

For the common interval certificate, the current margins are about

\[
\lambda_{\min}(P)=1.66\times10^{-3},
\]

\[
\lambda_{\min}(P-A_0^\mathsf TPA_0)=9.71\times10^{-5},
\]

\[
\lambda_{\min}(P-A_1^\mathsf TPA_1)=9.71\times10^{-5}.
\]

The logical step from these computed inequalities to exponential stability is the Lyapunov theorem and, for the interval, the induced-norm triangle inequality.

## 9. Limits of the proof

The common-`P` argument proves stability of the linearized conditioned family for arbitrary \(\beta_k\in[0,1]\). It does not prove global stability of the exact nonlinear switched plant while conditioning is active.

The exact nonlinear claim is local. Near the orbit, strict dwell margin forces \(\beta=1\), and the Schur Jacobian proves local exponential stability. Large-error simulations support behavior outside that neighborhood, but they are not a global proof.

The certificate is numerical. A formal computer-assisted proof would need interval or rational bounds for the generated matrices and Lyapunov inequalities.

## 10. Run the optimizations

From the paper project root:

```sh
task stability-proof
```

Or run the files separately:

```sh
matlab -batch "run('studies/signal-conditioning-stability/prove_beta_0.m')"
matlab -batch "run('studies/signal-conditioning-stability/prove_beta_1.m')"
matlab -batch "run('studies/signal-conditioning-stability/prove_beta_interval.m')"
```

All three scripts require YALMIP and SeDuMi on the MATLAB path. They stop if optimization fails or if direct numerical checks reject the returned certificate.
