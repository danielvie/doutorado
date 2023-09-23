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
    y  = engine.sim_1(cfg);
        
    % plot se exemplo patino 2 (suporte para monitorar calculo de traj)
    % y_ = y - y(1,:);
    % engine.helpers.plot_if_patino_2(y_);
    
    % calculando integral erro trajetoria (trapezios)
    ny  = size(y,1);
    dx  = cfg.tstep;
    I   = 0;
    v_  = 0;
    
    % garantindo que `xref` tem formato 1x3
    xref = reshape(xref, [1, 3]);
    for i = 1:ny
        % gerando valor da funcao
        xi = (y(i,:) - xref);
        v  = xi*Q*xi';

        % atualizando integrador
        I  = I + dx*(v + v_)/2;
        v_ = v;
    end
    
    % saida resultado
    J = I;    
end