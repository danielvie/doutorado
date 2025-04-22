function [Phi, Gamma] = get_phi_gamma(self)
    cfg = self.config;

    Ts  = cfg.Ts;
    tr  = Ts(2:end);
    xr  = Helpers.get_xr(self.config);

    [Phi, Gamma] = Mpc.construcao_modelo_instantes(cfg.A, cfg.b, tr, xr, cfg);   
    
    % print if no output is given
    if nargout == 0
        fprintf('Phi:\n');
        disp(Phi);
        fprintf('Gamma:\n');
        disp(Gamma);
    end
end
