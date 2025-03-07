function [y,t,u,m,xr, yy,tt,mm] = sim_cycle(~, config)

    % lendo configuracoes
    cfg = config;

    C     = cfg.C;
    D     = cfg.D;
    tstep = cfg.tstep;
    x0    = cfg.x0;
    Ts    = cfg.Ts;

    % simulando com parametros flexiveis
    n_modes = numel(cfg.Omega);
    nstates = size(cfg.A{1}, 2);
    
    % alocando vetores de saida 
    nmax = ceil(cfg.Tpmax/cfg.tstep);
    nvar = numel(cfg.xref);
    t    = zeros(nmax, 1);
    u    = zeros(nmax, 1);
    y    = zeros(nmax, nvar);
    m    = zeros(nmax, 1);
    
    % calculando simulacao
    xi0  = x0;
    xi0_ = x0;
    cont = 0;
    
    xr   = zeros(n_modes, numel(x0));
    xr(1,:) = x0;
    
    
    % alocando vetores estado extendido
    yy = zeros(n_modes, nstates);
    tt = zeros(n_modes, 1);
    mm = zeros(n_modes, 1);
    
    omega = cfg.Omega;

    for i = 1:n_modes
        % lendo modo de operacao (indice do modo inicia em `0`)
        imode =omega(i);
                
        % lendo matrizes A e B 
        Ai = cfg.A{imode};
        Bi = cfg.b{imode};
        
        % calculando ciclo
        ti = (Ts(i):tstep:Ts(i+1)-tstep)';
        % ui = ones(size(ti))*cfg.ur(imode);
        ui = ones(size(ti));
        mi = ones(size(ti))*imode;
        
        xi0  = reshape(xi0, [numel(xi0), 1]);
        yi   = lsim(Ai,Bi,C,D,ui,ti-ti(1),xi0);
        
        xi0 = yi(end, :);

        % concatenando resultado da iteraco
        nti  = numel(ti);
 
        t(cont+1:cont+nti)   = ti(:);
        u(cont+1:cont+nti)   = ui(:);
        y(cont+1:cont+nti,:) = yi(:,:);
        m(cont+1:cont+nti)   = mi(:);

        cont = cont + nti;
        
        xr(i+1,:) = xi0;





        % simulando com estado extendido
        xi0_ = reshape(xi0_, [numel(xi0_), 1]);
        dt   = Ts(i+1) - Ts(i);
        Fa   = expm([Ai,Bi;zeros(1,size(Ai,2)),0]*dt);
        

        if (i+1 <= n_modes)
            imode = omega(i+1);
        else
            imode = omega(i);
        end

        yend     = Fa*[xi0_;1];
        yy(i, :) = yend(1:nstates);
        tt(i)    = Ts(i+1);
        mm(i)    = imode;

        xi0_     = yend(1:nstates);

    end

    % adicionando primeiros valores
    x0 = reshape(x0, [1, nstates]);
    yy = [x0;yy];
    tt = [Ts(1);tt];
    mm = [cfg.Omega(1);mm];
    
    % removendo pontos nao usados da alocacao
    t = t(1:cont);
    u = u(1:cont);
    y = y(1:cont, :);
    m = m(1:cont);
end