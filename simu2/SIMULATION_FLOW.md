# Simulation Code Documentation

This document describes the flow of the simulation framework based on the entry point `play.m`.

## 1. Overview
The simulation is entry-pointed by `play.m` which orchestrates:
1.  **Initialization**: Creating the simulation environment.
2.  **Trajectory Setup**: Defining the reference periodic orbit.
3.  **Controller Setup**: Configuring Model Predictive Control (MPC).
4.  **Execution**: Running the main simulation loop.
5.  **Analysis**: Collecting and plotting results.

## 2. Detailed Flow

### 2.1 Initialization
The script starts by instantiating the `Simulation` class:
```matlab
s = Simulation(Enums.SimName.LAB_CIRCUIT);
```
*   **Source**: `@Simulation/Simulation.m`
*   **Action**:
    *   Sets up default configurations.
    *   Initializes logging structures (`m_log`).
    *   Sets the state mode (default: `ORIGINAL`).

### 2.2 Trajectory Setup
The reference trajectory (periodic orbit) is defined by a duty cycle parameter $\alpha$:
```matlab
s.set_traj_phase_with_alpha(0.5);
```
*   **Source**: `@Simulation/set_traj_phase_with_alpha.m` -> `@Simulation/set_traj_phase.m`
*   **Action**:
    *   Calculates the "industrial solution" for the given $\alpha$.
    *   Computes the optimal mode sequence (`Omega`) and duration for each mode (`Ts`) using `Utils.industrial_solution`.
    *   Updates `self.m_config.Omega` and `self.m_config.Ts`.
    *   Sets equilibrium state `x0` based on limits.

### 2.3 MPC Configuration
The MPC controller is configured and matrices are pre-computed:
```matlab
config_mpc = s.get_config_mpc();
config_mpc.Nd = 3;  % Control horizon
config_mpc.Np = 25; % Prediction horizon
s.set_config_mpc(config_mpc);
s.set_mpc();
```
*   **Source**: `@Simulation/set_mpc.m`
*   **Action**:
    *   Retrieves system matrices ($\Phi, \Gamma$) using `get_phi_gamma()`.
    *   Constructs the augmented model (if `Augmented` mode is used) or standard model.
    *   Sets up weighting matrices $Q$ and $R$.
    *   Computes switching constraints constants ($c$).

### 2.4 Simulation Execution
The core simulation runs for `nsim` cycles:
```matlab
s.m_config.mpc.on = true;
[y, t, m] = s.run(nsim);
```
*   **Source**: `@Simulation/run.m`
*   **Flow Scope**:
    1.  **Initialization**: `run_initialize_simulation` sets up memory buffers.
    2.  **Loop** (runs `nsim` times):
        *   **Control Computation**: `run_compute_control`.
            *   If MPC is ON: Computes control actions $\delta t_k$ (deviations in switching times) to minimize error $x_0 - x_{target}$.
            *   If MPC is OFF: $\delta t_k = 0$.
        *   **Constraint Application**: `run_apply_time_constraints`.
            *   Validates $\delta t_k$ against physical time limits using `condition_dtk_signal`.
            *   Updates the timing vector `Ts` for the current cycle.
        *   **Physics Simulation**: `run_simulation_cycle` -> calls `sim_cycle2`.
            *   **Source**: `@Simulation/sim_cycle2.m`
            *   Iterates through the mode sequence `Omega`.
            *   Propagates state using matrix exponential: $x_{k+1} = e^{(A_i \Delta t)} x_k + \dots$
        *   **Logging**: Records states, errors, and control efforts.
        *   **State Update**: Sets final state of current cycle as initial state of next cycle.

### 2.5 Results & Visualization
Finally, results are aggregated and plotted:
```matlab
res = Results.Patino2(vars);
res.plot_xi();
res.plot_traj();
```
*   **Source**: `+Results/Patino2.m`
*   **Action**: Wraps the raw data arrays (`y`, `t`, `m`) and provides high-level plotting methods for states, trajectories, and control signals.

## 3. Key Data Structures (Variables)
*   **config**: Holds system parameters, matrices ($A, B$), and timing configuration ($Ts, \Omega$).
*   **simulation_state**: Tracks dynamic state during running (`x0`, `mpc_on`, `Nd_counter`).
*   **dtk**: The control variable vector, representing time shifts applied to switching instances.
