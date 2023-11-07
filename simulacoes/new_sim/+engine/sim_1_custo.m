function [yi_, dt_] = sim_1_custo(config)

    % lendo configuracoes
    x0    = config.x0;

    % simulando com parametros flexiveis
    n_modes = numel(config.Omega);
        
    % calculando simulacao
    xi0  = x0;
        
    nstates = size(config.A{1}, 2);

    y     = zeros(n_modes,nstates);
    dtout = zeros(n_modes,1);

    yi_ = zeros(n_modes,nstates);
    dt_ = zeros(n_modes, 1);

    dt_modes = diff(config.Ts);
    for i = 1:n_modes
        % lendo modo de operacao (indice do modo inicia em `0`)
        imode = config.Omega(i) + 1;
                
        % lendo matrizes A e B 
        Ai = config.A{imode};
        bi = config.b{imode};
        
        % calculando ciclo
        dt = dt_modes(i);
        xi0 = reshape(xi0, [nstates, 1]);
        
        Fa  = expm([Ai,bi;zeros(1,size(Ai,2)),0]*dt);
        
        yend = Fa*[xi0;1];
        yi_(i,:) = yend(1:nstates);
        dt_(i) = dt;
        
        y(i,:) = yend(1:nstates);
        dtout(i) = dt;

        xi0 = yi_(i, :);
    end
    
end