function opt = get_otmin_opt(config)

    % 'Algorithm': 'active-set', 'interior-point', 'sqp', 'sqp-legacy', 'trust-region-reflective'
    % options = optimoptions('fmincon', 'display', 'iter' , 'DiffMinChange', config.tstep*10, 'Algorithm', 'sqp');

    opt = optimoptions('fmincon', 'DiffMinChange', config.tstep*10, 'StepTolerance', 1e-8, 'Algorithm', 'active-set');
end