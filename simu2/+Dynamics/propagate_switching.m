function [y, t, m, xr] = propagate_switching(config)
    % propagate_switching - Propagate system state at switching instants only.
    %
    % Computes the state evolution of a switched affine system using matrix
    % exponentials. Efficient for control loops where inter-sample behavior
    % is not needed.
    %
    % Inputs:
    %   config - struct with fields:
    %       .x0    : Initial state vector
    %       .Ts    : Switching time sequence [0, t1, ..., T]
    %       .Omega : Mode index sequence (1-indexed)
    %       .A     : Cell array of system matrices {A1, ..., An}
    %       .b     : Cell array of input vectors  {b1, ..., bn}
    %
    % Outputs:
    %   y  - (N x nstates) States at end of each mode interval
    %   t  - (N x 1)       Time at end of each mode interval
    %   m  - (N x 1)       Mode index for each interval
    %   xr - (N+1 x nstates) Full state trajectory [x(t0); x(t1); ...; x(tN)]

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

        % Computing state transition (augmented for affine system)
        % x_dot = Ax + Bu  =>  z_dot = [A B; 0 0]z, where z = [x; 1]
        Fa = expm([Ai, Bi; zeros_aug] * dt);

        % Propagate state
        xi0_col = reshape(xi0_curr, [], 1);
        yend_aug = Fa * [xi0_col; 1];

        % Extract next state
        xi0_next = yend_aug(1:nstates)';

        % Store results
        y(i,:)    = xi0_next;
        t(i)      = Ts(i+1);
        m(i)      = imode;
        xr(i+1,:) = xi0_next;

        % Update for next iteration
        xi0_curr = xi0_next;
    end
end
