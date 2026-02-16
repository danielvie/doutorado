# Simulation Framework Documentation

## Multi-Cell Buck-Boost Converter with MPC via Variable Switching Instants

> **Author:** Daniel Vieira  
> **Context:** PhD Research (DOUTORADO)  
> **Based on:** Patiño Thesis – Experimental validation of MPC on multi-cell converters

---

## Table of Contents

1. [Overview](#1-overview)
2. [Physical System](#2-physical-system)
3. [Project Structure](#3-project-structure)
4. [Core Classes](#4-core-classes)
5. [Simulation Flow](#5-simulation-flow)
6. [MPC Formulation](#6-mpc-formulation)
7. [Data Configurations](#7-data-configurations)
8. [Utilities Reference](#8-utilities-reference)
9. [Visualization](#9-visualization)
10. [Hardware Integration (BTBroker)](#10-hardware-integration-btbroker)
11. [Feasibility Region Projection](#11-feasibility-region-projection)
12. [Dependencies](#12-dependencies)
13. [Quick Start](#13-quick-start)

---

## 1. Overview

This MATLAB framework simulates and controls a **multi-cell Buck-Boost DC-DC converter** using **Model Predictive Control (MPC) with variable switching instants**. Rather than traditional duty-cycle modulation, the control action consists of **time deviations** ($\delta t_k$) applied to the switching instants within each cycle.

### Core Idea

The converter operates in a periodic switching cycle with $N$ modes. A nominal trajectory is defined by a duty cycle parameter $\alpha$. The MPC controller computes small adjustments ($\delta t_k$) to the nominal switching times to steer the system state $x = [v_{C1}, v_{C2}, i_L]^T$ toward the target equilibrium.

### Key Features

- Switched linear system simulation via matrix exponentials
- Proportional (LQR-based) controller with configurable downsampling
- Dual-mode MPC with switching constraints and terminal set (via `quadprog` + MPT Toolbox)
- Feasibility region projection and visualization
- Hardware interface via Bluetooth (ESP32 prototype through `@BTBroker`)
- Multiple circuit configurations (lab circuit, Patiño benchmarks)

---

## 2. Physical System

### 2.1 Three-Cell Buck-Boost Converter

The converter has **3 switching cells** ($u_1, u_2, u_3$), each being ON (1) or OFF (0), giving $2^3 = 8$ possible operating **modes** (0–7).

**State vector:**

$$x = \begin{bmatrix} v_{C1} \\ v_{C2} \\ i_L \end{bmatrix}$$

- $v_{C1}$: Voltage across capacitor 1 [V]
- $v_{C2}$: Voltage across capacitor 2 [V]
- $i_L$: Inductor current [A]

**Mode-to-switch mapping:**

| Mode | $u_1$ | $u_2$ | $u_3$ | Binary |
|------|-------|-------|-------|--------|
| 0    | 0     | 0     | 0     | 000    |
| 1    | 0     | 0     | 1     | 001    |
| 2    | 0     | 1     | 0     | 010    |
| 3    | 0     | 1     | 1     | 011    |
| 4    | 1     | 0     | 0     | 100    |
| 5    | 1     | 0     | 1     | 101    |
| 6    | 1     | 1     | 0     | 110    |
| 7    | 1     | 1     | 1     | 111    |

> **Note:** Modes are stored **1-indexed** internally (MATLAB convention). Mode 1 in code corresponds to physical mode 0 (all switches OFF).

### 2.2 Continuous-Time Dynamics

For each mode $\sigma$, the system evolves as:

$$\dot{x} = A_\sigma x + b_\sigma$$

where the matrices are constructed by `Utils.compute_buckboost`:

$$A_\sigma = \begin{bmatrix}
0 & 0 & \frac{u_2 - u_1}{C_1} \\
0 & 0 & \frac{u_3 - u_2}{C_2} \\
\frac{u_1 - u_2}{L} & \frac{u_2 - u_3}{L} & \frac{-R}{L}
\end{bmatrix}, \quad
b_\sigma = \begin{bmatrix} 0 \\ 0 \\ \frac{E \cdot u_3}{L} \end{bmatrix}$$

### 2.3 Lab Circuit Parameters

| Parameter | Symbol | Value |
|-----------|--------|-------|
| Supply voltage | $E$ | 5.0 V |
| Capacitor 1 | $C_1$ | 470 µF |
| Capacitor 2 | $C_2$ | 470 µF |
| Inductance | $L$ | 300 mH |
| Resistance | $R$ | 72.9 Ω (68 + 4.9) |
| Switching period | $T$ | 0.28 ms |
| Minimum switch time | $t_{min}$ | 3 µs |
| Simulation time step | $t_{step}$ | 1 µs |

---

## 3. Project Structure

```
simu2/
├── play.m                          # Main entry point (simulation runner)
├── SIMULATION_FLOW.md              # Legacy simulation flow documentation
├── DOCUMENTATION.md                # This file
│
├── @Simulation/                    # Core simulation class (class folder)
│   ├── Simulation.m                # Class definition & constructor
│   ├── run.m                       # Main simulation loop
│   ├── set_config.m                # Load circuit configuration by name
│   ├── set_traj_phase.m            # Set trajectory from params (hidden)
│   ├── set_traj_phase_with_alpha.m # Set trajectory from duty cycle α
│   ├── set_traj_phase_with_iref.m  # Set trajectory from reference current
│   ├── set_mpc.m                   # Configure MPC matrices and constraints
│   ├── set_controller.m            # Assign controller (Strategy pattern)
│   ├── set_offset.m                # Set offset for states
│   ├── set_config_mpc.m            # Set MPC config struct
│   ├── step_control.m              # Delegate control to m_controller
│   ├── step_actuation.m            # Convert dtk to timing (Ts), apply constraints
│   ├── sim_cycle_switching.m       # Simulate cycle at switching instants only
│   ├── sim_cycle_dense.m           # Dense simulation for plotting (lsim-based)
│   ├── run_mpc.m                   # Legacy MPC computation (uses K*ek)
│   ├── compute_ts_from_dtk.m       # Apply dtk adjustments to Ts vector
│   ├── condition_dtk_signal.m      # Constraint conditioning (static method)
│   ├── signal_process.m            # Signal processing for hardware interface
│   ├── get_phi_gamma.m             # Compute Φ and Γ linearized matrices
│   ├── get_switching_constraints.m # Compute switching constraint vector c
│   ├── get_config_mpc.m            # Get MPC configuration struct
│   ├── get_gain_k.m                # Get LQR gain K
│   ├── get_mode.m                  # Get mode sequence (0-indexed)
│   ├── get_mode_bin.m              # Get mode sequence in binary form
│   ├── get_time_us.m               # Get time intervals in microseconds
│   ├── get_target.m                # Get MPC target state
│   ├── get_msg_control_signal.m    # Format BLE message with control data
│   ├── project_feasibility_region.m# Compute and plot feasibility region
│   ├── project_with_alpha.m        # Projection automation for given α
│   ├── quantizacao.m               # Time quantization (hardware emulation)
│   ├── can_compute_phase.m         # Guard: check if config supports phase calc
│   ├── alpha.m                     # Alias: set_traj_phase_with_alpha
│   ├── iref.m                      # Alias: set_traj_phase_with_iref
│   └── name.m                      # Get simulation name string
│
├── @BTBroker/                      # Bluetooth hardware broker (class folder)
│   ├── BTBroker.m                  # Class definition (BLE connection to ESP32)
│   ├── connect.m / disconnect.m    # BLE connection management
│   ├── subscribe.m / unsubscribe.m # BLE characteristic subscription
│   ├── msg.m                       # Send raw message
│   ├── msg_handle_event.m          # Event callback handler
│   ├── msg_handle_process.m        # Message parsing/dispatching
│   ├── set_signal.m                # Send switching signal to device
│   ├── set_simulation.m            # Upload full simulation config
│   ├── get_signal.m                # Request signal from device
│   ├── get_status.m                # Request device status
│   ├── start.m / stop.m            # Start/stop converter operation
│   └── ... (aliases: s, ss, sa, so, x, st, ma, mb, v_on, v_off, etc.)
│
├── +Controllers/                   # Controller strategies (package)
│   ├── Controller.m                # Abstract base class
│   └── Proportional.m              # Proportional (LQR) controller with downsampling
│
├── +Mpc/                           # MPC formulation (package)
│   ├── construcao_modelo_instantes.m    # Linearized model (Φ, Γ) at switching instants
│   ├── construcao_modelo_aumentado.m    # Augmented model for control delay
│   ├── matrizes_ss_mpc_dualmode_switching.m  # MPC matrices (H, Hf, K, Pf, Sf, bf)
│   └── dualmode_switching.m             # QP solver wrapper (quadprog)
│
├── +Data/                          # Circuit configurations (package)
│   ├── Config.m                    # Configuration data class
│   ├── lab_circuit.m               # Lab prototype (3-cell, E=5V)
│   ├── patino_1.m                  # Patiño benchmark 1 (2-mode, simple)
│   ├── patino_2.m                  # Patiño benchmark 2 (3-cell, E=30V)
│   └── intduplo.m                  # Double integrator (academic example)
│
├── +Projecao/                      # Feasibility region projection (package)
│   ├── create_projection.m         # Compute feasibility polytope
│   ├── determina_oinf.m            # Maximal admissible set (O_inf)
│   └── +plotter/                   # Projection visualization
│       ├── +integrador/            # Plotter for double integrator
│       ├── +patino1/               # Plotter for Patiño 1
│       └── +patino2/               # Plotter for Patiño 2 / Lab Circuit
│
├── +Results/                       # Results handling (package)
│   ├── SimulationData.m            # Standardized data container
│   └── BuckBoostPlotter.m          # Visualization class (states, trajectory, control)
│
├── +Trajectory/                    # Trajectory planning (package)
│   └── Planner.m                   # Trajectory generation from α or i_ref
│
├── +Enums/                         # Enumerations (package)
│   ├── SimName.m                   # INTEGRADOR_DUPLO, PATINO_1, PATINO_2, LAB_CIRCUIT
│   ├── StateMode.m                 # ORIGINAL, AUGMENTED
│   └── QuantType.m                 # Traj, Sim
│
├── +Utils/                         # Utility functions (package)
│   ├── compute_buckboost.m         # Build A, b matrices for all 8 modes
│   ├── industrial_solution.m       # Compute Ω and ΔT from α, n, T
│   ├── get_x0.m                    # Compute periodic orbit equilibrium x₀
│   ├── get_xr.m                    # Propagate reference trajectory xr
│   ├── get_ts.m                    # Convert ΔT to cumulative Ts
│   ├── time_array_from_diff.m      # Cumulative sum from diff array
│   ├── compute_dt_time_signal.m    # Compute dt time signal for hardware
│   ├── signal_create.m             # Create BLE signal string
│   └── getAllVars.m                # Capture all caller workspace variables
│
├── +Interface/                     # Configuration interfaces (package)
│   ├── config.m                    # General config interface
│   └── config_mpc.m                # MPC config interface
│
├── transf/                         # Output/transfer directory (results, figures)
│
└── (scratch files)                 # bla.m, t.m, tt.m, test.m, etc.
```

---

## 4. Core Classes

### 4.1 `Simulation` (handle class)

**File:** `@Simulation/Simulation.m`

The central orchestrator of the simulation framework.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `m_config` | `Data.Config` | Circuit and simulation configuration |
| `m_config_mpc` | `struct` | MPC-specific parameters (Np, Nd) |
| `m_set_alpha_cache` | — | Cache for alpha computations |
| `m_state_mode` | `Enums.StateMode` | `ORIGINAL` or `AUGMENTED` |
| `m_log` | `struct` | Logging structure with `.run` and `.signal` sub-structs |
| `m_controller` | `Controllers.Controller` | Active controller instance (Strategy pattern) |

**Constructor:**

```matlab
s = Simulation(Enums.SimName.LAB_CIRCUIT);
```

Loads a circuit configuration via `set_config()`, initializes default MPC config, sets state mode to `ORIGINAL`, and creates the log structure.

### 4.2 `Controllers.Controller` (abstract handle class)

**File:** `+Controllers/Controller.m`

Abstract interface for all controller strategies.

**Abstract methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `compute_control` | `[dtk, exitflag, info] = compute_control(self, x, x_target)` | Compute control action |
| `reset` | `reset(self)` | Reset internal state for new simulation |

### 4.3 `Controllers.Proportional` (concrete controller)

**File:** `+Controllers/Proportional.m`

Implements proportional (LQR) feedback: $\delta t_k = -K \cdot e_k$, where $e_k = x - x_{target}$.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `K` | matrix | Gain matrix (from `dlqr`) |
| `Nd` | int | Downsampling factor (1 = compute every step) |
| `counter` | int | Internal counter for downsampling |
| `last_dtk` | vector | Cached control for hold mode |

**Downsampling behavior:**
- When `counter < Nd`: returns `last_dtk` (hold), `exitflag = 44`
- When `counter >= Nd`: computes `dtk = -K * ek`, resets counter, `exitflag = 1`

### 4.4 `Data.Config` (value class)

**File:** `+Data/Config.m`

Data container holding all simulation parameters.

**Properties:**

| Property | Description |
|----------|-------------|
| `sim_name` | `Enums.SimName` enum value |
| `Omega` | Mode sequence vector [N×1], 1-indexed |
| `smax` | Maximum number of modes |
| `A` | Cell array of system matrices `{A₁, A₂, ..., A₈}` |
| `b` | Cell array of input vectors `{b₁, b₂, ..., b₈}` |
| `C`, `D` | Output matrices |
| `tstep` | Dense simulation time step [s] |
| `xref` | Reference state vector |
| `Q` | State weighting matrix |
| `Tpmax` | Maximum cycle period [s] |
| `Ts` | Switching time sequence `[0, t₁, t₂, ..., T]` [s] |
| `x0` | Periodic orbit equilibrium state |
| `circuit_params` | Struct with `E`, `C1`, `C2`, `L`, `R` |
| `mpc` | MPC data struct (populated by `set_mpc`) |
| `c_time` | Constraint time(s) `[t_min₁, t_min₂]` [s] |
| `quant_traj` | Quantization step for trajectory |
| `quant_sim` | Quantization step for simulation |
| `kawa` | Debug flag (extended model toggle) |

### 4.5 `Results.SimulationData` (handle class)

**File:** `+Results/SimulationData.m`

Standardized container for simulation results.

**Properties:**

| Property | Description |
|----------|-------------|
| `t`, `y`, `m` | Time, states, modes (MPC ON) |
| `t_off`, `y_off`, `m_off` | Time, states, modes (MPC OFF / open loop) |
| `target` | Target state vector |
| `config` | Simulation configuration snapshot |

**Methods:**

| Method | Description |
|--------|-------------|
| `parse_vars(vars)` | Extract data from workspace variable struct |
| `calculate_metrics()` | Compute RMSE and final error for ON/OFF |

### 4.6 `Results.BuckBoostPlotter` (handle class)

**File:** `+Results/BuckBoostPlotter.m`

Visualization engine for Buck-Boost converter simulations.

**Methods:**

| Method | Description |
|--------|-------------|
| `plot_states()` | 3-subplot: $v_{C1}$, $v_{C2}$, $i_L$ vs. time |
| `plot_trajectory_comparison()` | 3D phase portrait (MPC ON vs. OFF) |
| `plot_control_signals(start, n)` | Staircase plot of mode sequence |
| `plot_trajectory_animated()` | Animated 3D trajectory evolution |
| `plot_trajectory_projections()` | 2D projections (vC1-vC2, vC1-iL, vC2-iL) |

---

## 5. Simulation Flow

### 5.1 Entry Point (`play.m`)

```matlab
function play()
    % 1. Create Simulation object
    s = Simulation(Enums.SimName.LAB_CIRCUIT);

    % 2. Set trajectory from duty cycle α
    s.set_traj_phase_with_alpha(0.5);

    % 3. Configure MPC
    config_mpc = s.get_config_mpc();
    config_mpc.Nd = 3;   % Control delay / downsampling
    config_mpc.Np = 25;  % Prediction horizon
    s.set_config_mpc(config_mpc);
    s.set_mpc();

    % 4. Set Controller (Strategy Pattern)
    K = s.get_gain_k();
    controller = Controllers.Proportional(K, 1);
    s.set_controller(controller);

    % 5. Run simulation
    nsim = 5000;
    s.m_config.x0 = [0; 0; 0];  % start from zero

    s.m_config.mpc.on = true;
    [y, t, m] = s.run(nsim);     % MPC ON

    s.m_config.mpc.on = false;
    [y_off, t_off, m_off] = s.run(nsim);  % Open loop

    % 6. Visualize
    vars = Utils.getAllVars();
    sim_data = Results.SimulationData(vars);
    plotter = Results.BuckBoostPlotter(sim_data);

    figure(1); plotter.plot_states();
    figure(2); plotter.plot_trajectory_comparison();
    figure(3); plotter.plot_control_signals(1, 50);
end
```

### 5.2 Main Loop (`run.m`)

```
for k = 1:nsim
    ┌─────────────────────────────────────────────────┐
    │ A. Control Step    [step_control]                │
    │    - Delegates to m_controller.compute_control() │
    │    - Returns dtk (time deviations)               │
    ├─────────────────────────────────────────────────┤
    │ B. Actuation Step  [step_actuation]              │
    │    - Converts dtk to µs                          │
    │    - Applies constraint conditioning             │
    │    - Rounds to integer µs (hardware emulation)   │
    │    - Computes new Ts vector                      │
    ├─────────────────────────────────────────────────┤
    │ C. Physics Step    [sim_cycle_switching]          │
    │    - Propagates states through mode sequence     │
    │    - Uses matrix exponential: expm([A,b;0,0]*dt) │
    ├─────────────────────────────────────────────────┤
    │ D. Logging                                       │
    │    - Updates pre-allocated result buffers         │
    │    - Records state, error, timing, dtk           │
    ├─────────────────────────────────────────────────┤
    │ E. State Propagation                             │
    │    - Final state → initial state of next cycle   │
    └─────────────────────────────────────────────────┘
end
```

### 5.3 Trajectory Setup Pipeline

```
set_traj_phase_with_alpha(α)
  │
  ├── Compute circuit params (iMax = E/R, iLref = α·iMax)
  │
  └── set_traj_phase(params)
        │
        ├── Utils.industrial_solution(α, n, T)
        │     → Returns: Ω (mode sequence), ΔT (time intervals)
        │
        ├── Filter ΔT < 1e-16 (remove negligible intervals)
        │
        ├── config.Omega = Ω
        ├── config.Ts    = Utils.get_ts(ΔT)  (cumulative)
        └── config.x0    = Utils.get_x0(config) (periodic orbit)
```

### 5.4 State Propagation (`sim_cycle_switching`)

For each mode $i$ in the sequence $\Omega$:

1. Read mode index: `imode = Omega(i)`
2. Read dynamics: `Ai = A{imode}`, `Bi = b{imode}`
3. Compute duration: `dt = Ts(i+1) - Ts(i)`
4. Build augmented matrix and propagate:

$$F_a = \exp\left(\begin{bmatrix} A_i & b_i \\ 0 & 0 \end{bmatrix} \cdot \Delta t\right)$$

$$\begin{bmatrix} x_{next} \\ 1 \end{bmatrix} = F_a \cdot \begin{bmatrix} x_{curr} \\ 1 \end{bmatrix}$$

This formulation handles the affine term $b_i$ (constant input) exactly via the augmented state technique.

---

## 6. MPC Formulation

### 6.1 Linearized Model at Switching Instants

**File:** `+Mpc/construcao_modelo_instantes.m`

The system is linearized around the nominal trajectory to obtain:

$$e(t_N) = \Phi \cdot e(t_0) + \Gamma \cdot \delta t$$

where:
- $e = x - x_{target}$ is the state error
- $\delta t = [\delta t_1, ..., \delta t_{N-1}]^T$ are the timing deviations (control variables)
- $\Phi = F_N \cdot F_{N-1} \cdots F_1$ is the one-cycle propagation matrix
- $\Gamma$ captures the sensitivity of the final state to switching time changes

Each column $j$ of $\Gamma$ is:

$$\Gamma_j = \left(\prod_{k=j+1}^{N} F_k\right) \cdot \left[(A_j - A_{j+1})\bar{x}(t_j) + b_j - b_{j+1}\right]$$

where $\bar{x}(t_j)$ is the reference state at switching instant $j$.

### 6.2 MPC Optimization

**File:** `+Mpc/matrizes_ss_mpc_dualmode_switching.m`

The prediction model over $N_p$ steps:

$$\mathbf{e} = H \cdot \mathbf{u} + \Phi_{1:N_p} \cdot e_k$$

where:
- $H$ is the $nN_p \times pN_p$ prediction matrix
- $\mathbf{u} = [\delta t_1^T, ..., \delta t_{N_p}^T]^T$ is the stacked control

**Cost function (dual-mode):**

$$J = \sum_{i=1}^{N_p} \left( e_i^T Q e_i + \delta t_i^T R \delta t_i \right) + e_{N_p}^T P_f e_{N_p}$$

where $P_f$ is the terminal cost from the discrete Lyapunov equation:

$$\bar{\Phi}^T P_f \bar{\Phi} - P_f + \bar{\Phi}^T Q \bar{\Phi} + K^T R K = 0$$

with $\bar{\Phi} = \Phi - \Gamma K$ and $K$ from `dlqr(Φ, Γ, Q, R)`.

**Switching constraints:**

$$L \cdot \delta t \leq c$$

where $L$ is a Toeplitz matrix enforcing $\delta t_{j+1} - \delta t_j \leq c_j$, and $c_j = -\Delta t_j^{ref} + t_{min}$ ensures minimum dwell time.

**Terminal set:** Computed via MPT Toolbox (`LTISystem.invariantSet`):

$$S_f \cdot e \leq b_f$$

### 6.3 QP Problem

**File:** `+Mpc/dualmode_switching.m`

Solved with `quadprog`:

$$\min_{\mathbf{u}} \frac{1}{2} \mathbf{u}^T H_{qp} \mathbf{u} + f_{qp}^T \mathbf{u}$$

$$\text{s.t.} \quad A_{qp} \mathbf{u} \leq b_{qp}$$

where:
- $H_{qp} = 2(H^T \bar{Q} H + \bar{R} + H_f^T P_f H_f)$  (symmetrized)
- $f_{qp} = 2(H^T \bar{Q} \Phi_{1:N_p} e_k + H_f^T P_f \Phi^{N_p} e_k)$
- $A_{qp} = \begin{bmatrix} -\bar{L} \\ S_f H_f \end{bmatrix}$
- $b_{qp} = \begin{bmatrix} -\bar{c} \\ b_f - S_f \Phi^{N_p} e_k \end{bmatrix}$

### 6.4 Augmented Model (for Control Delay)

**File:** `+Mpc/construcao_modelo_aumentado.m`

When `StateMode = AUGMENTED`, accounts for $N_d$-step control delay:

$$X_a = \begin{bmatrix} x \\ \delta t_{prev} \end{bmatrix}, \quad
A_a = \begin{bmatrix} \Phi^{N_d} & B_b \\ 0 & 0 \end{bmatrix}, \quad
B_a = \begin{bmatrix} 0 \\ I \end{bmatrix}$$

where $B_b = \left(\sum_{i=0}^{N_d-1} \Phi^i\right) \Gamma$.

### 6.5 Constraint Conditioning

**File:** `@Simulation/condition_dtk_signal.m` (static)

Before applying $\delta t_k$, a scaling factor $\alpha \in [0, 1]$ is computed to ensure no switching interval becomes shorter than `t_min`:

1. Compute the gap changes: `gap_change = diff([0; dtk; 0])`
2. For all gaps that shrink (`gap_change < 0`), limit: $\alpha \leq \frac{t_{min} - \text{gap}_{ref}}{\text{gap\_change}}$
3. Apply: `dtk_conditioned = α · dtk`

---

## 7. Data Configurations

### 7.1 Lab Circuit (`Data.lab_circuit`)

| Parameter | Value |
|-----------|-------|
| Type | 3-cell Buck-Boost |
| E | 5.0 V |
| C₁, C₂ | 470 µF |
| L | 300 mH |
| R | 72.9 Ω |
| T | 0.28 ms |
| t_min | 3 µs |
| Modes (α=0.5) | [5, 7, 3, 4, 2, 6] |
| Ts (α=0.5) | [0, 46.67, 93.33, 140.0, 186.67, 233.33, 280.0] µs |

### 7.2 Patiño 2 (`Data.patino_2`)

| Parameter | Value |
|-----------|-------|
| Type | 3-cell Buck-Boost |
| E | 30.0 V |
| C₁, C₂ | 40 µF |
| L | 10 mH |
| R | 10 Ω |
| t_min | 3 µs |
| Modes | [1, 2, 4, 8, 3, 1, 5, 8, 5] |

### 7.3 Patiño 1 (`Data.patino_1`)

| Parameter | Value |
|-----------|-------|
| Type | 2-mode switched system |
| Circuit | Simple Buck (R=L=C=E=1) |
| Modes | [1, 2] |

### 7.4 Double Integrator (`Data.intduplo`)

| Parameter | Value |
|-----------|-------|
| Type | Academic example (double integrator) |
| States | [position, velocity] |
| Modes | [1, 2, 3, 2] → inputs [+1, 0, -1, 0] |

---

## 8. Utilities Reference

### `+Utils` Package

| Function | Signature | Description |
|----------|-----------|-------------|
| `compute_buckboost` | `[A,b,C,D] = compute_buckboost(params)` | Build all 8 mode matrices from circuit parameters |
| `industrial_solution` | `[Ω, ΔT, tSwitch] = industrial_solution(α, n, T)` | Compute mode sequence and timing from duty cycle |
| `get_x0` | `x0 = get_x0(config)` | Solve for periodic orbit: $x_0 = (I - FF)^{-1} c$ |
| `get_xr` | `Xr = get_xr(config)` | Propagate reference trajectory at all switching instants |
| `get_ts` | `Ts = get_ts(dT)` | Convert time intervals to cumulative time vector |
| `time_array_from_diff` | `ts = time_array_from_diff(t_diff)` | Cumulative sum starting from 0 |
| `compute_dt_time_signal` | `time_dt = compute_dt_time_signal(time)` | Compute discrete time signal for hardware |
| `signal_create` | `signal = signal_create(time, mode)` | Format BLE signal string `"SIGNAL:t1,t2,...;m1,m2,..."` |
| `getAllVars` | `vout = getAllVars()` | Capture all variables from caller's workspace into struct |

### Industrial Solution Algorithm

Given duty cycle $\alpha$, number of cells $n$, and period $T$:

1. For each cell $i$: compute turn-on time $t_{on,i}$ and turn-off time $t_{off,i}$
2. Sort all switching events chronologically
3. Track binary state of each cell → decode mode sequence $\Omega$
4. Compute time intervals $\Delta T$ between consecutive events

### Periodic Orbit Computation (`get_x0`)

Using the identity (eq. 2.10 from thesis):

$$x(t_N) = FF \cdot x_0 + c$$

where $FF = F_N \cdot F_{N-1} \cdots F_1$ and $c$ accumulates the affine terms.

At steady state $x(t_N) = x_0$:

$$x_0 = (I - FF)^{-1} \cdot c$$

---

## 9. Visualization

### `Results.BuckBoostPlotter`

#### `plot_states()`
Three vertically stacked subplots showing the time evolution of $v_{C1}$, $v_{C2}$, and $i_L$.

#### `plot_trajectory_comparison()`
3D phase-space plot comparing MPC ON (blue) vs. Open Loop (red), with target marked.

#### `plot_control_signals(start, n)`
Staircase plot of the mode sequence over a selectable window of samples.

#### `plot_trajectory_animated()`
Animated 3D trajectory showing time evolution with moving markers.

#### `plot_trajectory_projections()`
Four-panel figure with 2D projections (vC1-vC2, vC1-iL, vC2-iL) plus 3D view.

---

## 10. Hardware Integration (BTBroker)

### Overview

The `@BTBroker` class interfaces with a real **ESP32-based Buck-Boost converter prototype** via **Bluetooth Low Energy (BLE)**.

### Connection

```matlab
b = BTBroker();  % Auto-connects using default UUIDs
% or
b = BTBroker(name, service_uuid, characteristic_uuid);
```

### Key Operations

| Command | Action |
|---------|--------|
| `b.start()` | Start converter switching |
| `b.stop()` | Stop converter |
| `b.set_signal(time_us, mode)` | Upload switching signal |
| `b.set_simulation()` | Upload full simulation config |
| `b.get_status()` | Read device status |
| `b.get_last_calc(n)` | Read last MPC computation from device |

### Convenience Aliases

| Alias | Full Form |
|-------|-----------|
| `b.s(α)` | Set simulation with alpha |
| `b.ss(α)` | Set and send complete signal |
| `b.sa(α)` | Start |
| `b.so(α)` | Stop |
| `b.x()` | Emergency stop |
| `b.st()` | Get status |
| `b.v_on()` / `b.v_off()` | Toggle verbose mode |

### Message Protocol

Messages are formatted as strings sent over BLE:

```
"SIGNAL:t1,t2,...,tn;m1,m2,...,mn"
"MESSAGE_DATA:rows;cols;K_flat;times;modes;target"
"START"
"STOP"
```

---

## 11. Feasibility Region Projection

### Overview

The `+Projecao` package computes and visualizes the **feasibility region** of the MPC problem — the set of initial states from which a feasible control sequence exists.

### Pipeline

```matlab
fig = s.project_feasibility_region();
```

1. Compute $\Phi$, $\Gamma$ from system model
2. Compute LQR gain $K$ and closed-loop matrix $A_f = \Phi - \Gamma K$
3. Determine maximal admissible set $O_\infty$ (`determina_oinf`)
4. Build full constraint polytope for horizons $N = 1, 2, 4$
5. Project to state space using MPT Toolbox `Polyhedron.projection()`
6. Plot the nested feasibility regions

### Dependencies

- **MPT Toolbox** (Multi-Parametric Toolbox) for `Polyhedron`, `projection`, `LTISystem`, `invariantSet`

---

## 12. Dependencies

| Dependency | Required By | Purpose |
|------------|-------------|---------|
| MATLAB (R2019b+) | All | Core platform |
| Control System Toolbox | `dlqr`, `c2d`, `lsim` | LQR design, discrete conversion, linear simulation |
| Optimization Toolbox | `quadprog` | QP solver for MPC |
| MPT Toolbox (3.0+) | `+Projecao`, `set_mpc` | Polytope operations, invariant sets |
| Instrument Control Toolbox | `@BTBroker` | BLE communication |

---

## 13. Quick Start

### Run a basic simulation

```matlab
% Navigate to simu2 directory
cd('path/to/simu2');

% Run the default simulation
play();
```

### Change duty cycle

```matlab
s = Simulation(Enums.SimName.LAB_CIRCUIT);
s.set_traj_phase_with_alpha(0.3);  % α = 0.3 (30%)
s.set_mpc();

K = s.get_gain_k();
s.set_controller(Controllers.Proportional(K, 1));

[y, t, m] = s.run(5000);
```

### Visualize feasibility region

```matlab
s = Simulation(Enums.SimName.LAB_CIRCUIT);
s.set_traj_phase_with_alpha(0.5);
s.set_mpc();

fig = s.project_feasibility_region();
```

### Connect to hardware

```matlab
b = BTBroker();
b.s(0.5);      % Set alpha = 0.5
b.sa();         % Start
pause(5);
b.st();         % Read status
b.x();          % Stop
```

---

## Appendix: Log Structure

After running `s.run(nsim)`, the log is available at `s.m_log.run`:

| Field | Size | Description |
|-------|------|-------------|
| `iter` | `nsim × 1` | Iteration index |
| `exitflag` | `nsim × 1` | Solver exit flag (1=ok, 44=held, 0=max iter, -2=infeasible) |
| `time_us` | `nsim × N` | Duration of each mode interval [µs] |
| `x0` | `nsim × n_states` | State at end of each cycle |
| `ek` | `nsim × n_states` | Error $e_k = x_0 - x_{target}$ |
| `ts` | `nsim × (N+1)` | Switching time sequence for each cycle |
| `x_target` | `nsim × n_states` | Target state |
| `time_qp` | `nsim × 1` | QP solver execution time [s] |
| `dtk` | `nsim × p` | Applied control action |
| `dtk_prev` | `nsim × p` | Previous control action |

> All log arrays are **pre-allocated** at initialization for O(1) insertion per iteration.
