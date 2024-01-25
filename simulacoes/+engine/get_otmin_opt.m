function opt = get_otmin_opt(config)

    % 'Algorithm': 'active-set', 'interior-point', 'sqp', 'sqp-legacy', 'trust-region-reflective'
    % options = optimoptions('fmincon', 'display', 'iter' , 'DiffMinChange', 1e-7, 'Algorithm', 'sqp');

    % opt = optimoptions('fmincon', 'DiffMinChange', 1e-7, 'StepTolerance', 1e-8, 'Algorithm', 'active-set');
    opt = optimoptions('fmincon', 'Algorithm','interior-point');
end