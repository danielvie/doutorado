# Theory and Mathematics

Physics and MPC formulation. Skip this if you just want to run simulations.

## Physical System

### State Vector

$$x = [v_{C1}, v_{C2}, i_L]^T$$

### Converter Switch States and Physical Mode IDs

3 switching cells → $2^3 = 8$ switch states with physical mode IDs 0-7:

| Physical mode ID | $u_1$ | $u_2$ | $u_3$ | Binary |
|------------------|-------|-------|-------|--------|
| 0 | 0 | 0 | 0 | 000 |
| 1 | 0 | 0 | 1 | 001 |
| ... | ... | ... | ... | ... |
| 7 | 1 | 1 | 1 | 111 |

> MATLAB dynamics index 1 selects physical mode ID 0. Keep dynamics indices and physical mode IDs distinct.

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
- $e = x - x_{target}$ (tracking error: actual minus active setpoint)
- $\delta t = [\delta t_1, ..., \delta t_{N-1}]^T$ (switching-time perturbations)
- $\Phi = F_N \cdot F_{N-1} \cdots F_1$ (one-cycle propagation)
- $\Gamma_j = \left(\prod_{k=j+1}^{N} F_k\right) \cdot \left[(A_j - A_{j+1})\bar{x}(t_j) + b_j - b_{j+1}\right]$

Here the active state setpoint is the nominal-orbit state at the controlled
cycle phase. At the cycle-start boundary it is the orbit anchor. The desired
operating point used to design the orbit is a separate quantity.

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

**Minimum dwell constraint**:

$$L \cdot \delta t \geq c, \qquad c = d_{min} - d_{nominal}$$

**Terminal set** (MPT Toolbox):

$$S_f \cdot e \leq b_f$$

### QP Problem

Solved via `quadprog`:

$$\min_{\mathbf{u}} \frac{1}{2} \mathbf{u}^T H_{qp} \mathbf{u} + f_{qp}^T \mathbf{u}$$

$$\text{s.t.} \quad A_{qp} \mathbf{u} \leq b_{qp}$$

## Held-Input Block Model

A newly computed action applies immediately and remains constant for a block
of $N_d$ switching cycles. One prediction transition spans that block:

$$A_b = \Phi^{N_d}, \qquad
B_b = \left(\sum_{i=0}^{N_d-1} \Phi^i\right) \Gamma$$

Thus $N_d$ is both the control update period and prediction-block length. It
is not an actuation delay.

### Experimental One-Block-Delay Model

`Enums.StateMode.AUGMENTED` retains the thesis's ambiguous delayed formulation:

$$X_a = \begin{bmatrix} e \\ \delta t_{prev} \end{bmatrix}, \quad
A_a = \begin{bmatrix} A_b & B_b \\ 0 & 0 \end{bmatrix}, \quad
B_a = \begin{bmatrix} 0 \\ I \end{bmatrix}$$

This model delays a newly selected action by one prediction block. The normal
`Simulation.run` path has no such delay, so this formulation is experimental.

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

The orbit anchor $\bar{x}_0$ satisfies:

$$\bar{x}_0 = (I - FF)^{-1} \cdot c$$

Where $FF = F_N \cdots F_1$ (full cycle propagation).

## Feasibility Region Projection

The finite-horizon feasible set contains predictor states for which an admissible plan exists over $N_p$ model transitions and satisfies the terminal constraint. This is current QP feasibility, not by itself recursive feasibility.

### Constraint Polytope

At each prediction step, the error evolves as:

$$\mathbf{e} = H \cdot \mathbf{u} + \Phi_{1:N_p} \cdot e_k$$

Subject to:
- Minimum dwell constraints: $L \cdot \delta t \geq c$
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
