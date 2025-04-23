function project_feasibility_region(self)
    fprintf('Projecting feasibility region...\n');

    [Phi, Gamma] = self.get_phi_gamma();

    % modelo discretizado com T = 0.1s
    % ?? eu faco essa discretizacao?

    config = struct();
    config.A = Phi;
    config.B = Gamma;

    % ganho de realimentacao K usando DLQR
    numel_x  = size(Phi, 2);
    numel_u  = size(Gamma,2);

    config.Q = diag(numel_x);
    config.R = diag(size(Gamma,2));

    % restricoes

    %{
        L dt >= c 
    %}

    % ?? dimensao da toeplitz, eh numel(c) x size(Gamma,2)?
    % L = toeplitz([1, -1, 0, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0, 0]);
    % L = toeplitz([1, -1, 0, 0, 0, 0], [1, 0, 0, 0, 0]);
    
    c = self.get_switching_constraints();
    
    p1 = zeros(1, numel(c));
    p2 = zeros(1, size(Gamma, 2));
    p1(1:2) = [1, -1];
    p2(1) = 1;
    
    L = toeplitz(p1, p2);

%     c = [
%    -0.7167
%    -0.1567
%    -0.7167
%    -0.1567
%    -0.7167
%    -0.1567
%     ] * 1e-4;


    config.Sx = zeros(1, numel_x);
    config.bx = 0;
    % config.Sx = eye(3)
    % config.bx = [30; 20; 20];

    config.Su = -L;
    config.bu = -c;

    config.xbar = self.config.x0;

    config.ubar = zeros(numel_u, 1);

    config.N  = 1;
    v1 = Projecao.create_projection(config);
    config.N  = 2;
    v2 = Projecao.create_projection(config);
    config.N  = 20;
    v4 = Projecao.create_projection(config);

    % deslocando origem 
    v1.D = v1.D + config.xbar;
    v2.D = v2.D + config.xbar;
    v4.D = v4.D + config.xbar;

    % PP = Polyhedron('H',[[eye(3);-eye(3)] 1000*ones(6,1)]);
    % PP = intersect(v.D,PP);
    % clf, plot(PP2)

    vars = Helpers.getAllVars();
    assignin('base', 'vars', vars);

    f1 = figure(2);
    
    if self.config.sim_name == Enums.SimName.PATINO_2
        Projecao.plotter.patino2.plot_projection(f1, v1, v2, v4, config.xbar, "N_p = 4", "N_p = 2", "N_p = 1")
    if self.config.sim_name == Enums.SimName.LAB_CIRCUIT
        Projecao.plotter.patino2.plot_projection(f1, v1, v2, v4, config.xbar, "N_p = 4", "N_p = 2", "N_p = 1")
    elseif self.config.sim_name == Enums.SimName.PATINO_1
        Projecao.plotter.patino1.plot_projection(f1, v1, v2, v4, config.xbar);
    elseif self.config.sim_name == Enums.SimName.INTEGRADOR_DUPLO
        Projecao.plotter.integrador.plot_projection(f1, v1, v2, v4, config.xbar);
    end

end
