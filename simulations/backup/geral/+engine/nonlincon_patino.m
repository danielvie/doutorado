function [c,ceq] = nonlincon_patino(config, X)
    % c(x)   <= 0
    % xeq(x)  = 0
    
    % lendo parametros de configuracao
    nmodes = numel(config.modes);
    nstate = numel(config.xref);
    
    dT   = X(1:nmodes);
    x0   = X(nmodes+1:nmodes+nstate);
    % dT   = X(1:2);
    % x0   = X(3:4);
    
    % ajustando condicao inicial
    config_ = config;
    config_.x0 = x0;
    
    % montando vetor de tempo e rodando simulacao
    Ts = zeros(1, numel(dT) + 1);
    for i = 2:numel(Ts)
        Ts(i) = Ts(i-1) + dT(i-1);
    end
    
    config_.Ts = Ts;
    % config_.Ts = [0, dT(1), sum(dT)];
    
    y  = doc.sim_1(config_);
    
    e  = config_.x0 - y(end,:);
    
    c   = [];
    
    ceq = sum(e.^2);
    
    bla = 1;
end