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
    
    x0     = config.otmin.x0;
    lb     = config.otmin.lb;
    ub     = config.otmin.ub;
    A      = config.otmin.A;
    b      = config.otmin.b;
    Aeq    = config.otmin.Aeq;
    beq    = config.otmin.beq;
    
    [x, fval] = fmincon(@(x) engine.fun_custo_patino(c, x), x0, A, b, Aeq, beq, lb, ub, [], opt);
    
    % atualizando valores
    dT = x;
    c.Ts = engine.get_ts(dT);
    c.x0 = engine.get_x0(c);
end