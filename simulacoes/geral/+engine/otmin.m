function [c, x, fval] = otmin(config, opt)
    c = config;
    
    % --------------------------------------
    % FMINCON
    % --------------------------------------
    
    if ~exist('opt', 'var')
        opt    = engine.get_otmin_opt(c);
        opt.ConstraintTolerance = 1e-8;
        opt.PlotFcn = 'optimplotfvalconstr';
    end
    
    % x0     = [0.25, 0.25, config.x0];
    % lb     = [0.25, 0.25, config.x0 - 2.0];
    % ub     = [1.50, 1.50, config.x0 + 2.0];
    x0     = [0.25, 0.25];
    lb     = [0.25, 0.25];
    ub     = [1.50, 1.50];
    A      = [];
    b      = [];
    Aeq    = [];
    beq    = [];
    
    [x, fval] = fmincon(@(x) engine.fun_custo_patino(c, x), x0, A, b, Aeq, beq, lb, ub, [], opt);
    
    % atualizando valores
    dT = x;
    c.Ts = engine.get_ts(dT);
    c.x0 = engine.get_x0(c);
end