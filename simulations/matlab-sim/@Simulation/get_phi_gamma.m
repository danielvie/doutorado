function [Phi, Gamma] = get_phi_gamma(self)
    % Compatibility view of the nominal one-cycle linear model.
    model = self.get_cycle_linear_model();
    Phi = model.Phi;
    Gamma = model.Gamma;
end
