function J = fun_custo_patino(config, X)
    
    % vetor temporatio para nao escrever em config de referencia
    cfg    = config;

    % lendo parametros de configuracao
    xref = cfg.xref;
    Q    = cfg.Q;

    % computando numero de modos de dinamica
    nmodes = numel(cfg.modes);
    
    % vetor de incremento de tempo
    dT   = X(1:nmodes);

    % montando vetor de tempo
    Ts = engine.get_ts(dT);    
    
    % atualizando config temporation para os instantes de chaveamento
    % e calculando a condicao inicial para uma trajetoria ciclica
    cfg.Ts = Ts;
    cfg.x0 = engine.get_x0(cfg);
    
    % calculando trajetoria com configuracao temporaria
    [y,dt_sim] = engine.sim_1_custo(cfg);

    ny_     = size(y,1);
    nstates = size(y,2);
    I  = 0;
    v_ = 0;

    xref = reshape(xref, [1, nstates]);

    for i = 1:ny_
        xi = (y(i,:) - xref);
        v  = xi*Q*xi';

        dx = dt_sim(i);
        I = I + dx*(v + v_)/2;
        v_ = v;
    end
    
    % saida resultado
    J = I;    
end