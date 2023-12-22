function [y,t,u,m,xr, yi_,tt_,mm_] = sim_cycle2(config)

    % lendo configuracoes
    config_ = config;

    C     = config_.C;
    D     = config_.D;
    tstep = config_.tstep;
    x0    = config_.x0;
    Ts    = config_.Ts;

    % simulando com parametros flexiveis
    n_modes = numel(config_.Omega);
    nstates = size(config_.A{1}, 2);
    
    % alocando vetores de saida 
    nmax = ceil(config_.Tpmax/config_.tstep);
    nvar = numel(config_.xref);
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
    
    yi_ = zeros(n_modes, nstates);
    tt_ = zeros(n_modes, 1);
    mm_ = zeros(n_modes, 1);
    for i = 1:n_modes
        % lendo modo de operacao (indice do modo inicia em `0`)
        imode = config_.Omega(i);
                
        % lendo matrizes A e B 
        Ai = config_.A{imode};
        Bi = config_.b{imode};
        
        % calculando ciclo
        ti = (Ts(i):tstep:Ts(i+1)-tstep)';
        % ui = ones(size(ti))*config_.ur(imode);
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
        xi0_      = reshape(xi0_, [numel(xi0_), 1]);
        dt        = ti(end)-ti(1);
        Fa        = expm([Ai,Bi;zeros(1,size(Ai,2)),0]*dt);
        
        yend      = Fa*[xi0_;1];
        yi_(i, :) = yend(1:nstates);
        tt_(i)    = Ts(i);
        mm_(i)    = imode;

        xi0_      = yend(1:numel(xi0_));

    end

    tt_ = [tt_;Ts(end)];
    mm_ = [mm_;mi(1)];
    
    % removendo pontos nao usados da alocacao
    t = t(1:cont);
    u = u(1:cont);
    y = y(1:cont, :);
    m = m(1:cont);
end