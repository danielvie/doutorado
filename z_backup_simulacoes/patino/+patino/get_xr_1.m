function xr = get_xr_1()

    %%
    % --------------------------------------
    % CONFIG INICIAL
    % --------------------------------------

    config = patino.init_sim_1();

    %%
    % --------------------------------------
    % FMINCON
    % --------------------------------------
    opt    = patino.get_otmin_opt(config);
    opt.ConstraintTolerance = 1e-8;
%     opt.PlotFcn = 'optimplotfvalconstr';

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

    [x, ~] = fmincon(@(x) patino.fun_custo_patino(config, x), x0, A, b, Aeq, beq, lb, ub, [], opt);

    % atualizando valores
    dT = x;
    config.Ts = patino.get_ts(dT);
    config.x0 = patino.get_x0(config);

    % calculando `xr`
    [~,~,~,~,xr] = patino.sim_1(config);

end