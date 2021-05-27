function [y,t,u,m] = sim_1(config)

    % lendo configuracoes
    Cc    = config.Cc;
    Dc    = config.Dc;
    tstep = config.tstep;
    x0    = config.x0;
    Ts    = config.Ts;

    % simulando com parametros flexiveis
    n_modes = numel(config.modes);
    
    % alocando vetores de saida 
    nmax = ceil(config.Tpmax/config.tstep);
    nvar = numel(config.xref);
    t    = zeros(nmax, 1);
    u    = zeros(nmax, 1);
    y    = zeros(nmax, nvar);
    m    = zeros(nmax, 1);
    
    % calculando simulacao
    xi0  = x0;
    cont = 0;
    for i = 1:n_modes
        % lendo modo de operacao (indice do modo inicia em `0`)
        imode = config.modes(i) + 1;
                
        % lendo matrizes A e B 
        Ai = config.Ac{imode};
        Bi = config.Bc{imode};
        
        % calculando ciclo
        ti = (Ts(i):tstep:Ts(i+1)-tstep)';
        ui = ones(size(ti))*config.ur(imode);
        mi = ones(size(ti))*(imode - 1);
        
        yi  = lsim(Ai,Bi,Cc,Dc,ui,ti-ti(1),xi0);
        xi0 = yi(end, :);
        
        % concatenando resultado da iteraco
        nti  = numel(ti);
 
        t(cont+1:cont+nti)   = ti(:);
        u(cont+1:cont+nti)   = ui(:);
        y(cont+1:cont+nti,:) = yi(:,:);
        m(cont+1:cont+nti)   = mi(:);

        cont = cont + nti;
    end
    
    % removendo pontos nao usados da alocacao
    t = t(1:cont);
    u = u(1:cont);
    y = y(1:cont, :);
    m = m(1:cont);
end