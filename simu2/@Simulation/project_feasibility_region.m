function fig = project_feasibility_region(self)
    % project_feasibility_region - Project the feasibility region of the system.
    % 
    % Note: This function uses the package +Projecao to create the projections
    %       the location of +Projecao is: ./simu2/+Projecao
    % 
    % Syntax: fig = project_feasibility_region(self)
    %
    % Inputs:
    %   self - Instance of the BTBroker class.
    %
    % Outputs:
    %   fig - Figure handle for the plot of the projected feasibility region.

    disp('Projecting feasibility region...');

    % Retrieve system matrices (Phi and Gamma) from the object
    [Phi, Gamma] = self.get_phi_gamma();

    % Create a configuration structure to store system parameters
    config = struct();
    config.A = Phi;
    config.B = Gamma;

    % Determine the dimensions of the state and input vectors
    numel_x  = size(Phi, 2);
    numel_u  = size(Gamma, 2);

    % Define weighting matrices for the DLQR controller
    config.Q = diag(numel_x);
    config.R = diag(size(Gamma, 2));

    % Retrieve switching constraints from the object
    c = self.get_switching_constraints();

    % Define the Toeplitz matrix for constraints
    p1 = zeros(1, numel(c));
    p2 = zeros(1, size(Gamma, 2));
    p1(1:2) = [1, -1];
    p2(1) = 1;
    L = toeplitz(p1, p2);

    % Define state and input constraints
    config.Sx = zeros(1, numel_x);
    config.bx = 0;
    config.Su = -L;
    config.bu = -c;

    % Set the initial state and input
    config.xbar = self.config.x0;
    config.ubar = zeros(numel_u, 1);

    % Generate projections for different prediction horizons
    config.N  = 1;
    v1 = Projecao.create_projection(config);
    config.N  = 2;
    v2 = Projecao.create_projection(config);
    config.N  = 4;
    v4 = Projecao.create_projection(config);

    % Shift the projections to account for the initial state
    v1.D = v1.D + config.xbar;
    v2.D = v2.D + config.xbar;
    v4.D = v4.D + config.xbar;

    % Export variables to the base workspace for debugging or analysis
    vars = Utils.getAllVars();
    assignin('base', 'vars', vars);

    % Create a figure for plotting
    fig = figure(2);

    % Plot the projections based on the simulation name
    if self.config.sim_name == Enums.SimName.PATINO_2
        Projecao.plotter.patino2.plot_projection(fig, v1, v2, v4, config.xbar, "N_p = 4", "N_p = 2", "N_p = 1");
    elseif self.config.sim_name == Enums.SimName.LAB_CIRCUIT
        Projecao.plotter.patino2.plot_projection(fig, v1, v2, v4, config.xbar, "N_p = 4", "N_p = 2", "N_p = 1");
    elseif self.config.sim_name == Enums.SimName.PATINO_1
        Projecao.plotter.patino1.plot_projection(fig, v1, v2, v4, config.xbar);
    elseif self.config.sim_name == Enums.SimName.INTEGRADOR_DUPLO
        Projecao.plotter.integrador.plot_projection(fig, v1, v2, v4, config.xbar);
    end
end
