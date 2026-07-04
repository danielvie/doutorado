function [Phi, Gamma] = get_phi_gamma(self)
    % get_phi_gamma - Delegates to Dynamics.linearize
    [Phi, Gamma] = Dynamics.linearize(self.m_config);
end
