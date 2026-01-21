function [y, t, m, xr] = sim_cycle_switching(~, config)
    % SIM_CYCLE_SWITCHING Simulates the system state only at switching instants.
    %
    % This function computes the state evolution of the switched system
    % using matrix exponentials. It is computationally efficient and suitable
    % for control loops (MPC) where inter-sample behavior is not critical.
    %
    % Inputs:
    %   config - struct containing:
    %       .x0    : Initial state vector
    %       .Ts    : Vector of switching times
    %       .Omega : Vector of mode indices (0-based or 1-based depending on system def)
    %       .A     : Cell array of system matrices A for each mode
    %       .b     : Cell array of input matrices B for each mode
    %
    % Outputs:
    %   y  - (N x nstates) States at the END of each mode interval.
    %   t  - (N x 1) Time at the END of each mode interval.
    %   m  - (N x 1) Mode index for each interval.
    %   xr - (N+1 x nstates) State trajectory including start [x(t0); x(t1); ... x(tn)]

    x0    = config.x0;
    Ts    = config.Ts;

    nmodes  = numel(config.Omega);
    nstates = numel(x0);

    % Allocating output vectors
    t    = zeros(nmodes, 1);
    y    = zeros(nmodes, nstates);
    m    = zeros(nmodes, 1);

    % Trajectory including initial state
    xr      = zeros(nmodes+1, nstates);
    xr(1,:) = x0(:)';

    % Current state for propagation
    xi0_curr = x0;

    % Aux vector for affine augmentation: [A b; 0 0]
    zeros_aug = [zeros(1, size(config.A{1}, 2)), 0];

    for i = 1:nmodes

        % Reading operation mode
        imode = config.Omega(i);

        % Reading matrices
        Ai = config.A{imode};
        Bi = config.b{imode};

        % Time interval duration
        dt = Ts(i+1) - Ts(i);

        % Computing state transition matrix (augmented for affine system)
        % x_dot = Ax + Bu  =>  z_dot = [A B; 0 0]z, where z = [x; 1]
        % (Assuming u is constant 1 or handled via B scaling)
        Fa = expm([Ai, Bi; zeros_aug] * dt);

        % Propagate state
        xi0_col = reshape(xi0_curr, [], 1);
        yend_aug = Fa * [xi0_col; 1];

        % Extract next state
        xi0_next = yend_aug(1:nstates)';

        % Store results
        y(i,:)   = xi0_next;
        t(i)     = Ts(i+1);
        m(i)     = imode;
        xr(i+1,:) = xi0_next;

        % Update for next iteration
        xi0_curr = xi0_next;
    end
end
