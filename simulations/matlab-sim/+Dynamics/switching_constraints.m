function c = switching_constraints(config)
    % switching_constraints - Compute the switching constraint vector c.
    %
    % For each switching interval, computes c_i = -dtr_i + t_min_i,
    % the maximum allowed negative deviation before violating minimum dwell time.
    %
    % Inputs:
    %   config - struct with fields:
    %       .Omega : Mode index sequence
    %       .Ts    : Switching time sequence
    %       .c_time: Minimum dwell time(s) [scalar or vector]
    %
    % Outputs:
    %   c - (N x 1) Constraint vector for switching times

    N  = numel(config.Omega);

    Ts  = config.Ts;
    dtr = diff(Ts);

    % constraint time
    c_time = config.c_time;
    c_time_numel = numel(c_time);

    c = zeros(N, 1);
    for i = 1:N
        c_time_i = rem(i-1, c_time_numel) + 1;
        c(i) = -dtr(i) + c_time(c_time_i);
    end

    % Print c if no output argument
    if nargout == 0
        fprintf('c:\n');
        disp(c);
    end
end
