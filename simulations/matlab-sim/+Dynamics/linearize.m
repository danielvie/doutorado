function [Phi, Gamma] = linearize(config)
    % linearize - Compute linearized model (Phi, Gamma) at switching instants.
    %
    % Computes the one-cycle propagation matrix Phi and the sensitivity
    % matrix Gamma relating switching-instant offsets to state changes.
    %
    % Inputs:
    %   config - struct with fields:
    %       .A, .b  : Cell arrays of system matrices per mode
    %       .Ts     : Nominal cycle-boundary times
    %       .Omega  : Dynamics-index sequence
    %       .orbit_anchor : Nominal state at the cycle-start boundary
    %       (and all fields required by Mpc.build_switching_model)
    %
    % Outputs:
    %   Phi   - (n x n) One-cycle state transition matrix
    %   Gamma - (n x p) Cycle-end sensitivity to switching-instant offsets

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
