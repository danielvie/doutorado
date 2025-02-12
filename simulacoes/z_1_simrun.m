function z_1_simrun() 
    % get data
    config = engine.get_config_sim_patino_2();
    
    % set system parameters
    params.E = 5;
    params.C(1) = 470e-6;
    params.C(2) = 470e-6;
    params.L = 100*1e-3;
    params.R = 22;

    params.n = 3; % number of switch cells
    params.T = 0.28*1e-3; % period of cycle

    params.iMax = params.E/params.R;

    % params.iLref = .1136363636; % <<< current setpoint
    % params.alpha = params.iLref / params.iMax;

    params.alpha = 0.7;
    params.iLref = params.alpha * params.iMax;
    
    % compute target trajectory
    [Omega, dT, tt] = phase_shift.industrial_solution(params.alpha, params.n, params.T);

    % compute system [A,b] dynamics
    [A,b] = phase_shift.modelSwitchedCapacitor(params.n,params.R,params.L,params.C,params.E);


end
