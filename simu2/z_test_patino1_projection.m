
% Define function for the projection test
function z_test_patino1_projection()
    s = Simulation(Enums.SimName.PATINO_1);
    
    [Phi, Gamma] = s.get_phi_gamma();
    
    % Get switching constraints using simu2 functions
    c_sys = s.get_switching_constraints();
    % Reconstruct L from Mpc.matrizes_ss_mpc_dualmode_switching or explicitly here
    p = size(Gamma, 2);
    N = p + 1;
    col = [1;-1;zeros(N-2,1)];
    row = [1 zeros(1,N-2)];
    L = toeplitz(col,row);
    
    % In projecao_patino1.m, config.Su = -L, config.bu = -c
    config.A = Phi;
    config.B = Gamma;
    config.Q = diag(size(Phi, 2));
    config.R = diag(size(Gamma, 2));
    config.Sx = zeros(1, size(Phi, 2));
    config.bx = 0;
    
    config.Su = -L;
    config.bu = -c_sys;
    
    % In projecao_patino1.m it's [-0.5; -1.0], but in simu2 x0_nominal is different
    % config.xbar = s.m_config.x0;
    config.xbar = [-0.5; -1.0];
    config.ubar = zeros(1, p);
    
    disp('Phi (simu2):'); disp(Phi);
    disp('Gamma (simu2):'); disp(Gamma);
    disp('L (simu2):'); disp(L);
    disp('c_sys (simu2):'); disp(c_sys);
    
    config.N = 1;
    v1 = Projecao.create_projection(config);
    config.N = 2;
    v2 = Projecao.create_projection(config);
    config.N = 4;
    v4 = Projecao.create_projection(config);
    
    v1.D = v1.D + config.xbar;
    v2.D = v2.D + config.xbar;
    v4.D = v4.D + config.xbar;
    
    f1 = figure(1);
    clf;
    Projecao.plotter.patino1.plot_projection(f1, v1, v2, v4, config.xbar);
    
    disp('Projection created successfully.');
end
