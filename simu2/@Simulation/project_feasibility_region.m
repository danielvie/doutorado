function fig = project_feasibility_region(self, horizons)
    % project_feasibility_region - Project the feasibility region of the system.
    % 
    % Note: This function uses the package +Projecao to create the projections.
    % 
    % Syntax: fig = project_feasibility_region(self, horizons)
    %
    % Inputs:
    %   self     - Instance of the Simulation class.
    %   horizons - (Optional) Array of prediction horizons (e.g., [1, 2, 4]).
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
    
    % The linearized model (Phi, Gamma) is defined at the beginning of the cycle.
    % The center of the projection should be this equilibrium state.
    xr = Utils.get_xr(self.m_config);
    x_eq = xr(1, :)';

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

    % Define state and input constraints
    config.Sx = zeros(0, numel_x); % Empty state constraint matrix
    config.bx = zeros(0, 1);       % No state constraints by default
    config.Su = -L;
    config.bu = -c;

    % Set the equilibrium state and input
    config.xbar = x_eq;
    config.ubar = zeros(numel_u, 1);

    % Generate projections for specified prediction horizons
    projections = cell(numel(horizons), 1);
    labels = cell(numel(horizons), 1);
    
    for i = 1:numel(horizons)
        config.N = horizons(i);
        res = Projecao.create_projection(config);
        v = res.D;
        % Shift the projection to account for the equilibrium point
        v = v + x_eq;
        
        % Wrap the Polyhedron in a struct with a 'D' property to maintain compatibility
        % with the legacy plotter functions in +Projecao/+plotter/
        proj_struct = struct();
        proj_struct.D = v;
        projections{i} = proj_struct;
        
        labels{i} = sprintf('N_p = %d', horizons(i));
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
