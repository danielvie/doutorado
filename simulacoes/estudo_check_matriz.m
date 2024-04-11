function res = estudo_check_matriz(pertubacao)
    
    if nargin < 1
        pertubacao = 0.05;
    end
    
    if numel(pertubacao) == 1
        pertubacao = {pertubacao};
    else
        aux = cell(1, numel(pertubacao));
        for i = 1:numel(pertubacao)
            aux{i} = pertubacao(i);
        end
        
        pertubacao = aux;
    end
    
    % get configuration
    config = engine.get_config_sim_patino_1();
    config.Ts = [0 0.2515 0.5015];

    %% calculo da trajetoria
    % [config, ~, ~] = engine.otmin(config);
    
    % fazer simulacao nominal
    nsim = 1;
    c = config;
    [y_, t_, u_, m_] = engine.sim_n(c, nsim);

    % fazer simulacao com perturbacao
    % (Ts nominal: [0 0.2515 0.5015])

    % CALCULAR EQUACOES DE PREDICAO
    tr  = config.Ts(2:end);
    xr  = engine.get_xr(config);

    [~, ~, Phi, Gamma] = mpc.construcao_modelo_instantes_aumentado(config.A, config.b, tr, xr, config);

    % calculando projecao dos estados para matrizes de predicao
    % e[tj, N] = Phi*e[tj, 0] + Gamma*dt[j];

    x0 = config.x0;
    xtarget = config.x0;
    numelx0 = numel(x0);


    cp = c;
    tam = numel(pertubacao);

    Y = cell(1, tam);
    T = cell(1, tam);
    U = cell(1, tam);
    M = cell(1, tam);
    E = cell(1, tam);

    for i = 1:numel(pertubacao)
        % calculando trajetoria pertubada
        p = pertubacao{i};
        cp.Ts = [0 0.2515 0.5015] + [0, p, 0];
        [y, t, u, m] = engine.sim_n(cp, nsim);

        dt = cp.Ts(2) - config.Ts(2);

        e0 = reshape(x0, [numelx0,1]) - reshape(xtarget, [numelx0,1]);
        ek = Phi*e0 + Gamma*dt;

        Y{i} = y;
        T{i} = t;
        U{i} = u;
        M{i} = m;
        E{i} = ek;
    end
    
    var_out = utils.getAllVars();
    res = resultados.ResPatino1_matriz(var_out);
    res.plot();
end