% Define function for the projection test
function z_projection_patino1()
    disp('Initializing simulation Patino 1...');
    s = Simulation(Enums.SimName.PATINO_1);

    disp('Extracting system dynamics...');
    [Phi, Gamma] = s.get_phi_gamma();
    c = s.get_switching_constraints();

    % Note: In some setups c(1) is exactly 0.0, which can lead to empty invariant
    % sets if not handled properly. We give it a tiny relaxation.
    c(1) = min(c(1), -1e-5);

    Q = s.m_config.Q;
    R = 1; % Scalar control weight

    % ==========================================================
    % 1. Find the Terminal Set (MAS - Maximal Admissible Set)
    % ==========================================================
    disp('Computing MAS (Maximal Admissible Set)...');

    % Unconstrained LQR gain
    K = dlqr(Phi, Gamma, Q, R);

    % The invariant set assumes u = -K*x.
    % The constraint is L*u >= c => L*(-K*x) >= c => -L*K*x >= c => L*K*x <= -c.
    L = [1; -1];
    Hmpt = [L*K, -c];

    % Constraints polyhedron X = {x | L*K*x <= -c}
    X_constraints = Polyhedron('H', Hmpt);

    % Form closed-loop autonomous system A_cl = Phi - Gamma*K
    sys_cl = LTISystem('A', Phi - Gamma*K);

    % Compute the invariant set under the closed loop dynamics
    Xf = sys_cl.invariantSet('X', X_constraints);

    % ==========================================================
    % 2. Formulate the MPT3 LTISystem for the MPC
    % ==========================================================
    disp('Defining MPT3 LTISystem...');
    sys = LTISystem('A', Phi, 'B', Gamma);

    % Set input constraints: L*u >= c =>  u >= c(1)  and  -u >= c(2) => u <= -c(2)
    sys.u.min = c(1);
    sys.u.max = -c(2);

    % State penalties
    sys.x.penalty = QuadFunction(Q);
    sys.u.penalty = QuadFunction(R);

    % Attach the computed terminal set to the system
    sys.x.with('terminalSet');
    sys.x.terminalSet = Xf;

    % ==========================================================
    % 3. Iterate over Horizons and Compute Projections (Domains)
    % ==========================================================
    horizons = [1, 2, 4];
    domains = cell(length(horizons), 1);
    colors = {'r', [0, 0.5, 0], 'b', 'm'};

    figure('Name', 'Feasibility Regions', 'Color', 'w');
    hold on; grid on;

    % Store handles for the legend
    h_leg = zeros(length(horizons), 1);

    for i = 1:length(horizons)
        Np = horizons(i);
        fprintf('Computing region for horizon Np = %d...\n', Np);

        % Formulate the MPC controller
        mpc = MPCController(sys, Np);

        % Convert to Explicit MPC to evaluate the exact parametric domain
        empc = mpc.toExplicit();

        % The domain of the partition is exactly the projected feasibility set
        P = empc.partition.Domain;
        domains{i} = P;

        % Plot the polyhedron
        plot(P, 'color', colors{i}, 'alpha', 0.4, 'linewidth', 1.0);

        % Create dummy plot for the legend (Polyhedron plot doesn't return nice handles for it)
        h_leg(i) = plot(NaN, NaN, 's', 'MarkerFaceColor', colors{i}, 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
    end

    % ==========================================================
    % 4. Formatting the Figure
    % ==========================================================
    xlabel('Error State x_1');
    ylabel('Error State x_2');
    title('Feasibility Regions for PATINO\_1');

    legend_labels = arrayfun(@(n) sprintf('N_p = %d', n), horizons, 'UniformOutput', false);
    legend(h_leg, legend_labels, 'Location', 'best');

    hold off;
    disp('Done.');
end
