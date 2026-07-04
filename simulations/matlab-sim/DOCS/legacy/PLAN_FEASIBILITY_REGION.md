# Plan: Feasibility Region Computation using MPT3

## 1. Evaluation of MPT3
**Is MPT3 a good tool for this?**
Yes, absolutely. The Multi-Parametric Toolbox 3 (MPT3) is the academic and industry standard in MATLAB for precisely this kind of task. It was designed specifically for parametric optimization, computational geometry, and Model Predictive Control (MPC). 

MPT3 natively supports:
*   Defining state-space models (`LTISystem`).
*   Handling convex polyhedra (`Polyhedron`), including intersections, Minkowski sums, and Pontryagin differences.
*   Computing Invariant Sets and Maximal Admissible Sets (MAS).
*   Executing polyhedral projections (e.g., projecting from state-input space down to just state space).
*   Built-in plotting capabilities for 2D and 3D polyhedra.

Given your requirements, MPT3 is exactly the right tool.

---

## 2. Prerequisites
Before computing the regions, ensure you extract the following from your current simulation dynamics:
*   **System Matrices:** $A$ and $B$ (Discrete-time linear system: $x_{k+1} = A x_k + B u_k$).
*   **State Constraints ($\mathcal{X}$):** Upper and lower bounds on your states (e.g., $x_{min} \le x \le x_{max}$).
*   **Control Constraints ($\mathcal{U}$):** Upper and lower bounds on your inputs (e.g., $u_{min} \le u \le u_{max}$).

---

## 3. Implementation Plan

### Step 1: Define the System and Constraints in MPT3
First, represent the dynamics and constraints using MPT3's object-oriented structure.
*   Create a `Polyhedron` for state constraints ($\mathcal{X}$).
*   Create a `Polyhedron` for input constraints ($\mathcal{U}$).
*   Construct an `LTISystem` object using the $A$ and $B$ matrices, attaching the constraints.

### Step 2: Compute the Maximal Admissible Set (MAS)
The MAS (often used as the terminal invariant set $\mathcal{X}_f$ in MPC) represents the region where the system can stay indefinitely while satisfying all constraints under a specific control law (like an LQR controller).
*   Compute the unconstrained LQR gain $K$.
*   Apply the closed-loop dynamics: $A_{cl} = A + B K$.
*   Use MPT3's built-in `invariantSet()` method on the closed-loop system to find the MAS.

### Step 3: Compute the Feasible Solution Polyhedron (Augmented Space)
For a given prediction horizon $N_p$, formulate the constraints over the entire horizon.
*   The augmented decision variable vector will be $Z = [x_0^T, u_0^T, u_1^T, \dots, u_{N_p-1}^T]^T$.
*   Formulate the equality constraints mapping $x_0$ and $u_k$ to future states $x_k$.
*   Enforce the inequality constraints:
    *   $x_k \in \mathcal{X}$ for $k = 0, \dots, N_p-1$
    *   $u_k \in \mathcal{U}$ for $k = 0, \dots, N_p-1$
    *   $x_{N_p} \in \mathcal{X}_f$ (The MAS computed in Step 2).
*   Build a single `Polyhedron` in this higher-dimensional space representing all these combined constraints.

*(Note: MPT3 can also do this automatically via the `MPCController` object, but computing the augmented polyhedron and projecting it manually gives you complete control as requested).*

### Step 4: Projection
The feasibility region in the state space is the set of all initial states $x_0$ for which there exists a valid sequence of controls. 
*   Use the `projection()` method on the augmented polyhedron from Step 3.
*   Project it onto the dimensions corresponding to $x_0$. 
*   This results in the exact feasible state space region $\mathcal{X}_{N_p}$.

### Step 5: Iteration and Visualization
*   Loop through your desired horizons: $N_p \in \{1, 2, 4\}$.
*   For each horizon, repeat Steps 3 and 4.
*   Store the resulting projected polyhedra.
*   Use MPT3's `plot()` function. Plot them on the same figure using different colors and alphas (transparency) to clearly show how the feasibility region grows as the horizon increases.

---

## 4. Conceptual MATLAB Script Skeleton

```matlab
% 1. Setup System
A = [...]; B = [...];
X = Polyhedron('lb', x_min, 'ub', x_max);
U = Polyhedron('lb', u_min, 'ub', u_max);
sys = LTISystem('A', A, 'B', B);
sys.x.min = x_min; sys.x.max = x_max;
sys.u.min = u_min; sys.u.max = u_max;

% 2. Find MAS (Terminal Set)
Q = eye(nx); R = eye(nu);
sys.x.penalty = QuadFunction(Q);
sys.u.penalty = QuadFunction(R);
Xf = sys.invariantSet(); % Computes MAS

% Horizons to evaluate
Np_values = [1, 2, 4];
feasible_regions = cell(length(Np_values), 1);
colors = {'red', 'green', 'blue'};

figure; hold on;

for i = 1:length(Np_values)
    Np = Np_values(i);
    
    % 3 & 4. Setup MPC and find domain (Automatic Projection approach via MPT3)
    % Setting the terminal set
    sys.x.with('terminalSet');
    sys.x.terminalSet = Xf;
    
    % Formulate the MPC problem
    mpc = MPCController(sys, Np);
    
    % The 'domain' of the explicit MPC controller is the projected feasible set!
    feasible_regions{i} = mpc.domain; 
    
    % 5. Plotting
    plot(feasible_regions{i}, 'color', colors{i}, 'alpha', 0.5);
end

legend('Np = 1', 'Np = 2', 'Np = 4');
title('Feasibility Regions for different Horizons');
xlabel('x_1'); ylabel('x_2');
grid on; hold off;
```

*(Note: The above code leverages MPT3's built-in `mpc.domain` which automatically handles the matrix lifting, polyhedral construction, and orthogonal projection in the background, minimizing the risk of indexing errors.)*