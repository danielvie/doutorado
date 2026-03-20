% Define function for the projection test using Backward Reachable Sets
function z_test_patino2_projection()
    disp('Initializing simulation Patino 2...');
    s = Simulation(Enums.SimName.PATINO_2);

    disp('Extracting system dynamics...');
    [Phi, Gamma] = s.get_phi_gamma();
    c = s.get_switching_constraints();

    n = size(Phi, 1);
    p = size(Gamma, 2);

    % Scale the inputs to improve numerical stability in MPT3 operations
    % Given very small values of 'c' (~1e-4), scaling avoids empty reachable sets
    u_scale = 1e4;
    Gamma = Gamma / u_scale;
    c = c * u_scale;

    % Note: In some setups c values can be exactly 0.0, which can lead to empty invariant
    % sets if not handled properly. We give it a tiny relaxation.
    c_relaxed = min(c, -1e-5 * u_scale);

    % Retrieve state weights, fallback to identity if not found
    Q = s.m_config.Q;
    if isempty(Q)
        Q = eye(n);
    end

    % Control weights (adjusted for scaling to maintain original LQR equivalent)
    R = eye(p) / (u_scale^2);

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
    Hmpt = [L*K, -c_relaxed];

    % Constraints polyhedron X = {x | L*K*x <= -c_relaxed}
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
    U_poly = Polyhedron(-L, -c_relaxed);
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
    colors = {'r', 'g', 'b', 'm'};

    figure('Name', 'Feasibility Regions', 'Color', 'w');
    hold on; grid on;

    % Store handles for the legend
    h_leg = zeros(length(horizons), 1);

    % Plot from largest horizon to smallest so smaller sets aren't hidden
    for i = length(horizons):-1:1
        P = domains{i};

        % Normalize H-rep rows before plotting to fix CDD vertex enumeration
        % numerical inconsistencies ("Numerical inconsistency is found").
        % The backward reachability iterations accumulate hyperplanes with
        % widely varying row norms, causing CDD's floating-point vertex
        % enumeration to fail. Normalizing each row to unit length fixes this.
        P = normalize_hrep(P);

        % Plot the polyhedron (MPT3 natively handles 3D plotting for Dim=3)
        plot(P, 'color', colors{i}, 'alpha', 0.2, 'linewidth', 1.0);

        % Create dummy plot for the legend (Using plot3 for 3D axes consistency)
        h_leg(i) = plot3(NaN, NaN, NaN, 's', 'MarkerFaceColor', colors{i}, 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
    end

    xlabel('Error State x_1');
    ylabel('Error State x_2');
    zlabel('Error State x_3');
    title('Feasibility Regions for PATINO\_2 (Backward Reachability)');
    view(3); % Force 3D view for 3 states

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
