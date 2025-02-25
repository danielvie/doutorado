function [y,t,m,xr] = sim_cycle2(self, config)

    % lendo configuracoes
    cfg = config;

    x0    = cfg.x0;
    Ts    = cfg.Ts;

    % simulando com parametros flexiveis
    nmodes  = numel(cfg.Omega);
    nstates = numel(x0);
    
    % alocando vetores de saida 
    t    = zeros(nmodes, 1);
    y    = zeros(nmodes, nstates);
    m    = zeros(nmodes, 1);
    
    % calculando simulacao
    xi0  = x0;
    xi0_ = x0;
    
    xr   = zeros(nmodes, numel(x0));
    xr(1,:) = x0;
    
    omega = cfg.Omega;
    for i = 1:nmodes

        % lendo modo de operacao (indice do modo inicia em `0`)
        imode = omega(i);
                
        % lendo matrizes A e B 
        Ai = cfg.A{imode};
        Bi = cfg.b{imode};
        
        xr(i+1,:) = xi0;

        % simulando com estado extendido
        xi0_ = reshape(xi0_, [numel(xi0_), 1]);
        dt   = Ts(i+1) - Ts(i);
        Fa   = expm([Ai,Bi;zeros(1,size(Ai,2)),0]*dt);

        
        % if (i+1 <= nmodes)
        %     imode = omega(i+1);
        % else
        %     imode = omega(i);
        % end

        yend     = Fa*[xi0_;1];


        % salvando valores de estado extendido
        % y    = [y; yend(1:nstates)';];
        % t    = [t; Ts(i+1)];
        % m    = [m; imode];
        y(i,:) = yend(1:nstates);
        t(i) = Ts(i+1);
        m(i) = imode;

        xi0_  = yend(1:nstates);

    end

    % adicionando primeiros valores
    % x0 = reshape(x0, [1, nstates]);
    % y = [x0;y];
    % t = [Ts(1);t];
    % m = [cfg.Omega(1);m];
    
end