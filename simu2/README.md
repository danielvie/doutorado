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

---
**Author:** Daniel Vieira  
**Context:** PhD Research (DOUTORADO)
