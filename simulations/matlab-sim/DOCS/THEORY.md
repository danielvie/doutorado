# Theory and Mathematics

Physics and MPC formulation. Skip this if you just want to run simulations.

## Physical System

### State Vector

$$x = [v_{C1}, v_{C2}, i_L]^T$$

### Converter Modes

3 switching cells → $2^3 = 8$ modes (0-7):

| Mode | $u_1$ | $u_2$ | $u_3$ | Binary |
|------|-------|-------|-------|--------|
| 0 | 0 | 0 | 0 | 000 |
| 1 | 0 | 0 | 1 | 001 |
| ... | ... | ... | ... | ... |
| 7 | 1 | 1 | 1 | 111 |

> MATLAB uses 1-indexing: Mode 1 = physical mode 0.

### Dynamics per Mode

$$\dot{x} = A_\sigma x + b_\sigma$$

$$A_\sigma = \begin{bmatrix}
0 & 0 & \frac{u_2 - u_1}{C_1} \\
0 & 0 & \frac{u_3 - u_2}{C_2} \\
\frac{u_1 - u_2}{L} & \frac{u_2 - u_3}{L} & \frac{-R}{L}
\end{bmatrix}, \quad
b_\sigma = \begin{bmatrix} 0 \\ 0 \\ \frac{E \cdot u_3}{L} \end{bmatrix}$$

### State Propagation

Using augmented matrix for exact solution:

$$F_a = \exp\left(\begin{bmatrix} A & b \\ 0 & 0 \end{bmatrix} \Delta t\right)$$

$$\begin{bmatrix} x_{next} \\ 1 \end{bmatrix} = F_a \begin{bmatrix} x_{curr} \\ 1 \end{bmatrix}$$

## MPC Formulation

### Linearization at Switching Instants

$$e(t_N) = \Phi \cdot e(t_0) + \Gamma \cdot \delta t$$

Where:
- $e = x - x_{target}$ (state error)
- $\delta t = [\delta t_1, ..., \delta t_{N-1}]^T$ (control: timing deviations)
- $\Phi = F_N \cdot F_{N-1} \cdots F_1$ (one-cycle propagation)
- $\Gamma_j = \left(\prod_{k=j+1}^{N} F_k\right) \cdot \left[(A_j - A_{j+1})\bar{x}(t_j) + b_j - b_{j+1}\right]$

### Prediction Model

Over horizon $N_p$:

$$\mathbf{e} = H \cdot \mathbf{u} + \Phi_{1:N_p} \cdot e_k$$

Where $\mathbf{u} = [\delta t_1^T, ..., \delta t_{N_p}^T]^T$

### Cost Function (Dual-Mode)

$$J = \sum_{i=1}^{N_p} \left( e_i^T Q e_i + \delta t_i^T R \delta t_i \right) + e_{N_p}^T P_f e_{N_p}$$

Terminal cost $P_f$ from discrete Lyapunov equation:

$$\bar{\Phi}^T P_f \bar{\Phi} - P_f + \bar{\Phi}^T Q \bar{\Phi} + K^T R K = 0$$

With $\bar{\Phi} = \Phi - \Gamma K$ and $K$ from `dlqr(Φ, Γ, Q, R)`.

### Constraints

**Switching constraints** (minimum dwell time):

$$L \cdot \delta t \leq c$$

**Terminal set** (MPT Toolbox):

$$S_f \cdot e \leq b_f$$

### QP Problem

Solved via `quadprog`:

$$\min_{\mathbf{u}} \frac{1}{2} \mathbf{u}^T H_{qp} \mathbf{u} + f_{qp}^T \mathbf{u}$$

$$\text{s.t.} \quad A_{qp} \mathbf{u} \leq b_{qp}$$

## Augmented Model (Control Delay)

For $N_d$-step delay compensation:

$$X_a = \begin{bmatrix} x \\ \delta t_{prev} \end{bmatrix}, \quad
A_a = \begin{bmatrix} \Phi^{N_d} & B_b \\ 0 & 0 \end{bmatrix}, \quad
B_a = \begin{bmatrix} 0 \\ I \end{bmatrix}$$

Where $B_b = \left(\sum_{i=0}^{N_d-1} \Phi^i\right) \Gamma$

## Circuit Parameters

### LAB_CIRCUIT

| Parameter | Value |
|-----------|-------|
| E | 5.0 V |
| $C_1, C_2$ | 470 µF |
| L | 300 mH |
| R | 72.9 Ω |
| T | 0.28 ms |
| $t_{min}$ | 3 µs |

### PATINO_2

| Parameter | Value |
|-----------|-------|
| E | 30.0 V |
| $C_1, C_2$ | 40 µF |
| L | 10 mH |
| R | 10 Ω |

## Periodic Orbit

Equilibrium $x_0$ satisfies:

$$x_0 = (I - FF)^{-1} \cdot c$$

Where $FF = F_N \cdots F_1$ (full cycle propagation).

## Feasibility Region Projection

The feasibility region is the set of initial errors $e_0 = x_0 - x_{target}$ for which the MPC optimization remains feasible over a prediction horizon $N_p$.

### Constraint Polytope

At each prediction step, the error evolves as:

$$\mathbf{e} = H \cdot \mathbf{u} + \Phi_{1:N_p} \cdot e_k$$

Subject to:
- Switching constraints: $L \cdot \delta t \leq c$
- Terminal set: $S_f \cdot e_{N_p} \leq b_f$

### Projection via MPT3

The region is computed by projecting the high-dimensional constraint polytope onto the state-error subspace using the MPT Toolbox:

1. Build the lifted constraint set in $(e_0, \mathbf{u})$ space
2. Eliminate the optimization variables $\mathbf{u}$ via projection
3. The resulting polytope in $e_0$-space defines the feasibility region

### Visualization

`Simulation.project_feasibility_region(horizons)` plots 2D projections (typically $v_{C1}$ vs $v_{C2}$, $v_{C1}$ vs $i_L$, $v_{C2}$ vs $i_L$) for different horizons:

```matlab
s.alpha(0.5);
s.set_mpc();
fig = s.project_feasibility_region([1, 2, 4, 8]);
```

Larger $N_p$ generally expands the feasibility region because the controller has more degrees of freedom to recover from disturbances.
