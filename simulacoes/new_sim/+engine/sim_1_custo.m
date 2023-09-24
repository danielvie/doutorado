function [yi_, dt_] = sim_1_custo(config)

    % lendo configuracoes
    tstep = config.tstep;
    x0    = config.x0;
    Ts    = config.Ts;

    % simulando com parametros flexiveis
    n_modes = numel(config.modes);
        
    % calculando simulacao
    xi0  = x0;
        
    nstates = size(config.Ac{1}, 2);


    y     = zeros(n_modes,nstates);
    dtout = zeros(n_modes,1);

    yi_ = [];
    dt_ = [];

    dt_modes = diff(config.Ts);
    for i = 1:n_modes
        % lendo modo de operacao (indice do modo inicia em `0`)
        imode = config.modes(i) + 1;
                
        % lendo matrizes A e B 
        Ai = config.Ac{imode};
        bi = config.Bc{imode};
        
        % calculando ciclo
        ti = (Ts(i):tstep:Ts(i+1)-tstep)';
        
        dt = dt_modes(i);
        xi0 = reshape(xi0, [nstates, 1]);
        
        Fa  = expm([Ai,bi;zeros(1,size(Ai,2)),0]*dt);
        
        yend = Fa*[xi0;1];
        yi_ = [yi_;yend(1:3)'];
        dt_ = [dt_;dt];
        
        y(i,:) = yend(1:3);
        dtout(i) = dt;

        xi0 = yi_(end, :);
    end
    
end