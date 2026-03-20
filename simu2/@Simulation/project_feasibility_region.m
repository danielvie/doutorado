function fig = project_feasibility_region(self, horizons, x_eq_in)
    % project_feasibility_region - Project the feasibility region of the system.
    % 
    % Note: This function uses the package +Projecao to create the projections.
    % 
    % Syntax: fig = project_feasibility_region(self, horizons, x_eq_in)
    %
    % Inputs:
    %   self     - Instance of the Simulation class.
    %   horizons - (Optional) Array of prediction horizons (e.g., [1, 2, 4]).
    %   x_eq_in  - (Optional) Custom equilibrium state vector to center the projection.
    %
    % Outputs:
    %   fig - Figure handle for the plot.

    if nargin < 2 || isempty(horizons)
        horizons = [1, 2, 4];
    end

    disp('Projecting feasibility region...');
    fprintf('Horizons: [%s]\n', num2str(horizons));

    % Retrieve system matrices (Phi and Gamma) and the equilibrium state
    [Phi, Gamma] = self.get_phi_gamma();
    
    % The center of the projection should be the target equilibrium state.
    if nargin >= 3 && ~isempty(x_eq_in)
        x_eq = x_eq_in;
    else
        x_eq = self.get_target();
    end

    % Create a configuration structure
    config = struct();
    config.A = Phi;
    config.B = Gamma;

    % Determine dimensions
    numel_x  = size(Phi, 2);
    numel_u  = size(Gamma, 2);

    % Get weighting matrices from the MPC setup if already configured
    if isfield(self.m_config, 'mpc') && isfield(self.m_config.mpc, 'Qbar')
        config.Q = self.m_config_mpc.Q;
        if isempty(config.Q)
            config.Q = diag(ones(1, numel_x));
        end
        config.R = diag(ones(1, numel_u));
    else
        config.Q = diag(ones(1, numel_x));
        config.R = diag(ones(1, numel_u));
    end

    % Retrieve switching constraints from the object
    c = self.get_switching_constraints();

    % Define the Toeplitz matrix for constraints (Delta u >= c)
    p1 = zeros(1, numel(c));
    p2 = zeros(1, numel_u);
    p1(1:2) = [1, -1];
    p2(1) = 1;
    L = toeplitz(p1, p2);

    % Define state and input constraints.
    % IMPORTANT: Use zeros(1, numel_x) (one zero row), NOT zeros(0, numel_x).
    % The zero-row constraint 0*x <= 0 anchors the LP in determina_oinf at the origin,
    % allowing linprog to properly test redundancy. Without it, the set starts unbounded
    % and the MAS characterization never converges.
    config.Sx = zeros(1, numel_x);
    config.bx = 0;
    config.Su = -L;
    config.bu = -c;

    % Set the equilibrium state and input
    config.xbar = x_eq;
    config.ubar = zeros(numel_u, 1);

    % Generate projections for specified prediction horizons
    projections = cell(numel(horizons), 1);
    labels = cell(numel(horizons), 1);
    all_D = cell(numel(horizons), 1);
    
    % --- Pass 1: Compute raw projections in error space ---
    for i = 1:numel(horizons)
        config.N = horizons(i);
        res = Projecao.create_projection(config);
        
        % CRITICAL: Capture the Sf/bf from the very first horizon call (N=1)
        % and reuse them for all subsequent horizons to guarantee mathematical nesting.
        if i == 1
            config.Sf = res.Sf;
            config.bf = res.bf;
        end
        
        all_D{i} = res.D;
        labels{i} = sprintf('N_p = %d', horizons(i));
    end

    % --- Pass 2: Apply consistent offset to all regions (just the equilibrium point) ---
    for i = 1:numel(horizons)
        proj_struct = struct();
        
        % deslocando para o ponto de equilibrio
        proj_struct.D = all_D{i} + config.xbar;
        
        projections{i} = proj_struct;
    end

    % Create a new figure for plotting
    fig = figure();
    
    % Plot the projections based on the simulation name
    if self.m_config.sim_name == Enums.SimName.PATINO_2 || ...
       self.m_config.sim_name == Enums.SimName.LAB_CIRCUIT
        Projecao.plotter.patino2.plot_projection(fig, projections{:}, x_eq, labels{:});
    elseif self.m_config.sim_name == Enums.SimName.PATINO_1
        Projecao.plotter.patino1.plot_projection(fig, projections{:}, x_eq, labels{:});
    elseif self.m_config.sim_name == Enums.SimName.INTEGRADOR_DUPLO
        Projecao.plotter.integrador.plot_projection(fig, projections{:}, x_eq, labels{:});
    end
end
