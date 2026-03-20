# Multi-Cell Buck-Boost Converter Simulation & Control (MPC)

This MATLAB framework facilitates the simulation and control of **Multi-Cell Buck-Boost DC-DC converters** using advanced **Model Predictive Control (MPC)** techniques with **Variable Switching Instants**. 

Developed as part of PhD research, the project bridges the gap between theoretical switched-system dynamics and real-world hardware implementation via Bluetooth integration.

## 🚀 Key Features
- **Variable Switching Control**: Implements control by adjusting switching time deviations ($\delta t_k$) rather than traditional duty-cycle modulation.
- **Dual-Mode MPC**: Supports state-space optimization via Quadratic Programming (`quadprog`) with timing and switching constraints.
- **Hardware-in-the-loop**: Integrated `@BTBroker` class for real-time communication with **ESP32-based prototypes** via Bluetooth Low Energy (BLE).
- **Flexible Dynamics**: Modular physics engine (`+Dynamics`) using matrix exponentials for exact state propagation of switched linear systems.
- **Advanced Visualization**: Specialized plotting tools for 3D phase-space trajectories, state evolution, and control signal analysis.
- **Feasibility Analysis**: Automated projection of MPC feasibility regions using the Multi-Parametric Toolbox (MPT).

## 📂 Project Structure
- `play.md`: Main entry point for running simulations and visualizing results.
- `@Simulation`: Central coordinator class managing the simulation lifecycle.
- `+Controllers`: Strategy-based implementations of Proportional (LQR) and MPC controllers.
- `+Dynamics`: Physics engine for state propagation and system linearization ($\Phi$, $\Gamma$).
- `+Trajectory`: Planners for generating reference periodic orbits from duty cycles ($\alpha$).
- `+Data`: Configuration profiles for various circuits.
- `@BTBroker`: Hardware interface for BLE communication with physical converters.
- `+Results`: Standardized data containers and specialized Buck-Boost visualization classes.

## 📊 Available Data Configurations (`+Data`)
The framework supports multiple circuit and benchmark types:
- **`LAB_CIRCUIT`**: 3-cell Buck-Boost converter ($E=5V$) modeling the actual lab prototype.
- **`PATINO_1` / `PATINO_2`**: System-level benchmarks for MPC validation based on the Patiño thesis ($E=30V$).
- **`INTDUPLO`**: A simplified Double Integrator model for testing basic QP and controller stability.

## 🛠️ Quick Start: Simple Simulation
To run a basic simulation in your command window:

```matlab
% 1. Create a simulation object for the Lab Prototype
s = Simulation(Enums.SimName.LAB_CIRCUIT);

% 2. Set the desired duty cycle (alphabetic factor between 0 and 1)
s.set_traj_phase_with_alpha(0.5);

% 3. Pre-compute MPC matrices and constraints
s.set_mpc();

% 4. Run the simulation for 1000 switching cycles
[y, t, m] = s.run(1000);

% 5. Visualize the results
vars = Utils.getAllVars();
sim_data = Results.SimulationData(vars);
plotter = Results.BuckBoostPlotter(sim_data);
plotter.plot_states();
```

## 📝 Core Concepts
### State Vector
The system tracks the voltages across capacitors and the inductor current:
$$x = [v_{C1}, v_{C2}, i_L]^T$$

### Control Strategy
The controller computes small time shifts $\delta t_k$ applied to a nominal switching sequence. This ensures that the system reaches its equilibrium state while respecting hardware limits ($t_{min}$) and avoiding overlapping switching events.

## 🎮 Advanced Simulation Example (Patino 2)
Here is a comprehensive example showing how to run the `PATINO_2` simulation, customize the Model Predictive Controller (MPC) parameters, change the controller type, and enable augmented state mode.

```matlab
% 1. Create a simulation object for Patino 2
s = Simulation(Enums.SimName.PATINO_2);

% --- State Mode (Augmented states) ---
% By default, the simulation uses ORIGINAL states. You can switch to AUGMENTED
% state mode if your dynamics or delay compensation require an expanded state vector:
s.m_state_mode = Enums.StateMode.AUGMENTED;

% 2. Retrieve and customize MPC configuration
config_mpc = s.get_config_mpc();
config_mpc.Nd = 1;              % Downsampling factor
config_mpc.Np = 2;              % Prediction horizon
config_mpc.Q = diag([1, 1, 1]); % Custom weighting matrix for the 3 states

% Build and apply MPC matrices (generates s.m_config.mpc data)
s.set_config_mpc(config_mpc);
s.set_mpc();

% --- Controller Selection ---
% You must explicitly instantiate a controller and attach it to the simulation.
% 
% Option A: Use the MPC Controller (solves the QP optimization at each step)
mpc_data = s.m_config.mpc;
controller = Controllers.MpcController(mpc_data);

% Option B: Use the Proportional Controller (LQR-based fallback/alternative)
% K = s.get_gain_k();
% time_us = s.get_time_us();
% controller = Controllers.Proportional(K, 1, time_us, 3*1e-6);

% Attach chosen controller
s.set_controller(controller);

% 3. Run the simulation (With Controller)
nsim = 100;
s.m_config.mpc.on = true;   % Enable control action
[y, t, m] = s.run(nsim);

% 4. (Optional) Run open loop for comparison
s.m_config.mpc.on = false;  % Disable control action
s.m_config.x0 = s.m_config.x0 + [-1.2; -1.3; -0.9]; % Introduce initial error
[y_off, t_off, m_off] = s.run(nsim);
```

---
**Author:** Daniel Vieira  
**Context:** PhD Research (DOUTORADO)
