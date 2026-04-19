# Multi-Cell Buck-Boost Converter MPC

MATLAB framework for Model Predictive Control of DC-DC converters using variable switching instants.

## Quick Start

### Using Task Runner (Recommended)

```matlab
t('play')              % Run main LAB_CIRCUIT simulation
t('play_patino1')      % Patino 1 benchmark
t('play_patino2')      % Patino 2 benchmark
t('play_integrador')   % Double integrator
t('test')              % Run test suite
t('demo', 'projection')% Run feasibility demo
```

### Manual Control

```matlab
% Basic simulation
s = Simulation(Enums.SimName.LAB_CIRCUIT);
s.alpha(0.5);           % Set duty cycle
s.set_mpc();            % Configure MPC
[y, t, m] = s.run(1000); % Run 1000 cycles

% Visualize
vars = Utils.getAllVars();
plotter = Results.BuckBoostPlotter(Results.SimulationData(vars));
plotter.plot_states();
```

## What This Does

Instead of traditional PWM duty-cycle control, this framework computes **time deviations** ($\delta t_k$) applied to switching instants. The controller steers the converter state $x = [v_{C1}, v_{C2}, i_L]^T$ toward equilibrium by adjusting when switches toggle.

**Key Features:**
- MPC via Quadratic Programming (`quadprog`)
- Proportional (LQR) fallback controller
- Hardware interface for ESP32 prototype (Bluetooth)
- Feasibility region visualization (MPT3)

## Documentation

| Document                                             | Purpose                      |
| ---------------------------------------------------- | ---------------------------- |
| [`DOCS/GETTING_STARTED.md`](DOCS/GETTING_STARTED.md) | First-time user tutorial     |
| [`DOCS/COOKBOOK.md`](DOCS/COOKBOOK.md)               | Common commands and patterns |
| [`DOCS/THEORY.md`](DOCS/THEORY.md)                   | Physics and MPC mathematics  |
| [`DOCS/API_REFERENCE.md`](DOCS/API_REFERENCE.md)     | Class and function reference |

## Installation

**Requirements:**
- MATLAB R2019b+
- Control System Toolbox (`dlqr`, `c2d`)
- Optimization Toolbox (`quadprog`)
- MPT Toolbox 3.0+ (for feasibility regions)
- Instrument Control Toolbox (for hardware/BLE)

**Setup:**
```matlab
addpath('C:/path/to/simu2');
```

## Project Structure

```
+Controllers/   +Data/      +Dynamics/   +Enums/
+Hardware/      +Interface/ +Mpc/        +Results/
+Trajectory/    +Utils/     +z_run/      @BTBroker/
@Simulation/

Core engine:     +* packages, @* classes
Run scripts:     +z_run/+Scripts/ (+Tests/, +Demos/)
Entry point:     t.m
Documentation:   DOCS/
```

## Supported Configurations

| Config             | Type              | Voltage | Purpose                |
| ------------------ | ----------------- | ------- | ---------------------- |
| `LAB_CIRCUIT`      | 3-cell Buck-Boost | 5V      | Physical lab prototype |
| `PATINO_2`         | 3-cell Buck-Boost | 30V     | Thesis benchmark       |
| `PATINO_1`         | 2-mode system     | 1V      | Simple validation      |
| `INTEGRADOR_DUPLO` | Double integrator | -       | Academic testing       |

## Hardware (Optional)

Connect to ESP32 prototype via Bluetooth:

```matlab
b = BTBroker();  % Auto-connect
b.alpha(0.5);    % Upload config
b.sa();          % Start
b.x();           % Stop (emergency)
```

See [`DOCS/COOKBOOK.md`](DOCS/COOKBOOK.md) for full hardware commands.

---

**Author:** Daniel Vieira | PhD Research (DOUTORADO)
