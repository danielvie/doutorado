function [y, t, m, u, xr] = propagate_dense(config)
    % propagate_dense - Simulate with high time resolution using lsim.
    %
    % Computes the dense (intra-mode) trajectory of the system for plotting
    % and detailed analysis.
    %
    % Inputs:
    %   config - struct with fields:
    %       .x0    : Initial state vector
    %       .Ts    : Switching time sequence [0, t1, ..., T]
    %       .Omega : Mode index sequence (1-indexed)
    %       .A, .b : Cell arrays of system matrices per mode
    %       .C, .D : Output matrices
    %       .tstep : Time step for dense simulation
    %
    % Outputs:
    %   y  - (M x nvar)     Dense system outputs over time
    %   t  - (M x 1)        Dense time vector
    %   m  - (M x 1)        Dense mode vector
    %   u  - (M x 1)        Dense input vector
    %   xr - (N+1 x nstates) State trajectory at switching instants (sparse)

    C     = config.C;
    D     = config.D;
    tstep = config.tstep;
    x0    = config.x0;
    Ts    = config.Ts;

    nmodes = numel(config.Omega);

    % Estimation of total steps for pre-allocation
    total_time = Ts(end) - Ts(1);
    nmax = ceil(total_time / tstep) + 2 * nmodes;
    nvar = size(C, 1);

    % Allocate dense outputs
    t = zeros(nmax, 1);
    u = zeros(nmax, 1);
    y = zeros(nmax, nvar);
    m = zeros(nmax, 1);

    % Allocate sparse state trajectory
    xr = zeros(nmodes + 1, numel(x0));
    xr(1,:) = x0(:)';

    % Current state for propagation
    xi0_curr = x0;

    idx_current = 0;

    for i = 1:nmodes
        % Reading operation mode
        imode = config.Omega(i);

        % Reading matrices
        Ai = config.A{imode};
        Bi = config.b{imode};

        % Time vector for this segment
        ti_seg = (Ts(i):tstep:Ts(i+1)-tstep)';

        % Ensure we capture the interval if step logic misses it
        if isempty(ti_seg) || (ti_seg(end) < Ts(i+1) - 1e-9)
             if isempty(ti_seg)
                 ti_seg = [Ts(i)];
             end
        end

        % Inputs (assuming unit step as per original logic)
        ui_seg = ones(size(ti_seg));
        mi_seg = ones(size(ti_seg)) * imode;

        % Run linear simulation (shift time to 0 for lsim)
        xi0_col = reshape(xi0_curr, [], 1);
        yi_seg = lsim(Ai, Bi, C, D, ui_seg, ti_seg - ti_seg(1), xi0_col);
        xi_seg = yi_seg;

        % Propagate remainder if lsim didn't reach end of interval
        x_end_sim = xi_seg(end, :);
        t_last_sim = ti_seg(end);

        if t_last_sim < Ts(i+1) - 1e-9
             dt_rem = Ts(i+1) - t_last_sim;
             zeros_aug = [zeros(1, size(Ai, 2)), 0];
             Fa = expm([Ai, Bi; zeros_aug] * dt_rem);
             x_end_aug = Fa * [x_end_sim(:); 1];
             xi0_curr = x_end_aug(1:end-1)';
        else
             xi0_curr = x_end_sim;
        end

        xr(i+1, :) = xi0_curr;

        % Store dense data
        n_seg = numel(ti_seg);
        range = idx_current + (1:n_seg);

        % Handle allocation overflow
        if range(end) > size(y, 1)
            padding = max(1000, n_seg);
            y = [y; zeros(padding, nvar)];
            t = [t; zeros(padding, 1)];
            u = [u; zeros(padding, 1)];
            m = [m; zeros(padding, 1)];
        end

        y(range, :) = yi_seg;
        t(range)    = ti_seg;
        u(range)    = ui_seg;
        m(range)    = mi_seg;

        idx_current = idx_current + n_seg;
    end

    % Trim outputs
    y = y(1:idx_current, :);
    t = t(1:idx_current);
    u = u(1:idx_current);
    m = m(1:idx_current);
end
