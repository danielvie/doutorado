function [Phi, Gamma] = get_phi_gamma(self)
    cfg = self.m_config;

    Ts  = cfg.Ts;
    tr  = Ts(2:end);
    xr  = Utils.get_xr(self.m_config);

    [Phi, Gamma] = Mpc.construcao_modelo_instantes(cfg.A, cfg.b, tr, xr, cfg);   
    
    % construindo modelo extendido
    
    % Ab = eye(size(Phi));

    % Aa = [Ab, Bb; zeros(size(Bb, 2), size(Ab, 2)), eye(size(Bb, 2))];
    % Ba = [0; 1];
    
    % fprintf('Modelo extendido:\n');
    % disp(Aa)
    % disp(Ba)
    
    % print if no output is given
    if nargout == 0
        fprintf('Phi:\n');
        disp(Phi);
        fprintf('Gamma:\n');
        disp(Gamma);
    end
end
