function [Phi, Gamma] = linearize(config)
    % linearize - Compute linearized model (Phi, Gamma) at switching instants.
    %
    % Computes the one-cycle propagation matrix Phi and the sensitivity
    % matrix Gamma relating switching time deviations to state changes.
    %
    % Inputs:
    %   config - struct with fields:
    %       .A, .b  : Cell arrays of system matrices per mode
    %       .Ts     : Switching time sequence
    %       .Omega  : Mode index sequence
    %       .x0     : Periodic orbit equilibrium state
    %       (and all fields required by Mpc.build_switching_model)
    %
    % Outputs:
    %   Phi   - (n x n) One-cycle state transition matrix
    %   Gamma - (n x p) Sensitivity of final state to switching time deviations

    Ts  = config.Ts;
    tr  = Ts(2:end);
    xr  = Utils.get_xr(config);

    [Phi, Gamma] = Mpc.build_switching_model(config.A, config.b, tr, xr, config);

    % Print if no output is given (interactive use)
    if nargout == 0
        fprintf('Phi:\n');
        disp(Phi);
        fprintf('Gamma:\n');
        disp(Gamma);
    end
end
