% Define function for the projection test using Backward Reachable Sets
function z_test_integrador_duplo_projection()
    disp('Initializing simulation Integrador Duplo...');
    s = Simulation(Enums.SimName.INTEGRADOR_DUPLO);

    disp('Extracting system dynamics...');
    [Phi, Gamma] = s.get_phi_gamma();
    c = s.get_switching_constraints();

    n = size(Phi, 1);
    p = size(Gamma, 2);

    % Retrieve state weights, fallback to identity if not found
    Q = s.m_config.Q;
    if isempty(Q)
        Q = eye(n);
    end

    % Control weights
    R = eye(p);

    % ==========================================================
    % 1. Find the Terminal Set (MAS - Maximal Admissible Set)
    % ==========================================================
    disp('Computing MAS (Maximal Admissible Set)...');

    % Unconstrained LQR gain
    K = dlqr(Phi, Gamma, Q, R);

    % Construct the L matrix for the switching constraints
    % L is of size (p+1) x p
    col = [1; -1; zeros(p-1, 1)];
    row = [1, zeros(1, p-1)];
    L = toeplitz(col, row);

    % The constraint is L*u >= c => -L*u <= -c
    % In closed loop u = -K*x, so -L*(-K*x) <= -c => L*K*x <= -c
    Hmpt = [L*K, -c];

    % Constraints polyhedron X = {x | L*K*x <= -c}
    X_constraints = Polyhedron('H', Hmpt);

    % Form closed-loop autonomous system A_cl = Phi - Gamma*K
    sys_cl = LTISystem('A', Phi - Gamma*K);

    % Compute the invariant set under the closed loop dynamics
    Xf = sys_cl.invariantSet('X', X_constraints);

    % ==========================================================
    % 2. Formulate the MPT3 LTISystem
    % ==========================================================
    disp('Defining MPT3 LTISystem...');
    sys = LTISystem('A', Phi, 'B', Gamma);

    % Set input constraints: -L*u <= -c
    U_poly = Polyhedron(-L, -c);
    sys.u.with('setConstraint');
    sys.u.setConstraint = U_poly;

    % ==========================================================
    % 3. Iterate over Horizons and Compute Backward Reachable Sets
    % ==========================================================
    horizons = [1, 2, 4];
    max_Np = max(horizons);

    domains = cell(length(horizons), 1);

    % Initialize the reachable set as the terminal invariant set
    R_current = Xf;

    for k = 1:max_Np
        fprintf('Computing backward reachable set for step %d...\n', k);

        % Compute 1-step backward reachable set from the current set
        R_current = sys.reachableSet('X', R_current, 'N', 1, 'direction', 'backward');

        % Minimize representation to improve performance and stability of next steps
        R_current.minHRep();

        % If this step matches one of our target horizons, save it
        idx = find(horizons == k);
        if ~isempty(idx)
            domains{idx} = R_current;
        end
    end

    % ==========================================================
    % 4. Formatting and Plotting the Figure
    % ==========================================================
    colors = {'r', [0, 0.5, 0], 'b', 'm'};

    figure('Name', 'Feasibility Regions', 'Color', 'w');
    hold on; grid on;

    % Store handles for the legend
    h_leg = zeros(length(horizons), 1);

    % Plot from largest horizon to smallest so smaller sets aren't hidden
    for i = length(horizons):-1:1
        P = domains{i};

        % Normalize H-rep rows before plotting to fix CDD vertex enumeration
        % numerical inconsistencies.
        P = normalize_hrep(P);

        % Plot the polyhedron
        plot(P, 'color', colors{i}, 'alpha', 0.3, 'linewidth', 1.0);

        % Create dummy plot for the legend
        h_leg(i) = plot(NaN, NaN, 's', 'MarkerFaceColor', colors{i}, 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
    end

    xlabel('Error State x_1');
    ylabel('Error State x_2');
    title('Feasibility Regions for INTEGRADOR\_DUPLO (Backward Reachability)');

    legend_labels = arrayfun(@(n) sprintf('N_p = %d', n), horizons, 'UniformOutput', false);
    legend(h_leg, legend_labels, 'Location', 'best');

    hold off;
    disp('Done.');
end


function P_out = normalize_hrep(P)
    % normalize_hrep - Normalize H-representation rows to unit length.
    %
    % CDD (the vertex enumeration engine used by MPT3) uses fixed numerical
    % tolerances. When rows of the A matrix (in A*x <= b) have widely different
    % norms, CDD misclassifies vertices and produces corrupted geometry.
    % Dividing each row [a_i | b_i] by ||a_i||_2 makes all rows comparable.
    %
    % Input:  P     - Polyhedron with H-rep (A*x <= b)
    % Output: P_out - Polyhedron with normalized H-rep

    A_h = P.A;
    b_h = P.b;

    row_norms = sqrt(sum(A_h.^2, 2));
    A_n = A_h ./ row_norms;
    b_n = b_h ./ row_norms;

    P_out = Polyhedron(A_n, b_n);
    P_out.minHRep();
end
