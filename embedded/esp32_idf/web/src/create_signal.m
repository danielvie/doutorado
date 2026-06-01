function [time_vector, mode_vector] = create_signal(alpha)
% CREATE_SIGNAL Creates a switching signal based on a duty cycle.
%   [time_vector, mode_vector] = CREATE_SIGNAL(alpha) returns:
%       - time_vector: time intervals in microseconds (rounded)
%       - mode_vector: switching modes (0-based)
%   matching the outputs shown in the Signal Generator web interface.
%
%   Example:
%       [time_vector, mode_vector] = create_signal(0.4)
%
%   Copyright 2025 ITA (Instituto Tecnologico de Aeronautica).

    n = 3; % Number of switch cells
    T = 0.28 * 1e-3; % Period of switching cycle (seconds)

    % Step 1: Define t0, ton, toff and initial state of the ith switch cell
    t0 = zeros(1, n);
    ton = zeros(1, n);
    toff = zeros(1, n);
    initialState = zeros(1, n);

    for i = 1:n
        % Initial time is evenly distributed across the period
        t0(i) = (i - 1) * T / n;

        % Calculate turn-off and turn-on times based on duty cycle
        toff(i) = mod(t0(i) + alpha * T / 2, T);
        ton(i) = mod(t0(i) + T - alpha * T / 2, T);

        % Determine initial state based on relative positions of ton and toff
        if ton(i) < toff(i)
            initialState(i) = 0; % Initially OFF
        else
            initialState(i) = 1; % Initially ON
        end
    end

    % Step 2: Obtain switching times in chronological order
    tSwitch_unsorted = [ton, toff];
    [tSwitch, indexSort] = sort(tSwitch_unsorted);

    % Step 3: Obtain mode sequence in binary coding form
    OmegaBin = zeros(2 * n, n);
    OmegaBin(1, :) = initialState;

    % Create an array to map sorted indices back to switch IDs (1-based)
    aux = 1:n;
    SwitchUnsorted = [aux, aux];
    SwitchId = SwitchUnsorted(indexSort);

    % Generate the sequence of switch states after each switching event
    for i = 1:(2 * n - 1)
        previousState = OmegaBin(i, :);
        SwitchToChange = SwitchId(i);
        newState = previousState;
        newState(SwitchToChange) = 1 - previousState(SwitchToChange);
        OmegaBin(i + 1, :) = newState;
    end

    % Step 4: Convert the binary mode sequence to decimal form (1-based)
    Omega = zeros(1, 2 * n);
    powers = 2.^( (n - 1):-1:0 );
    for i = 1:(2 * n)
        Omega(i) = 1 + sum(OmegaBin(i, :) .* powers);
    end

    % Step 5: Calculate time intervals between switching events (dtSwitch)
    dtSwitch = diff([0, tSwitch]);
    dtSwitch(1) = dtSwitch(1) + T - tSwitch(end);

    % Format output vectors to match Signal Generator web interface:
    % - time_vector: time intervals in microseconds (rounded)
    % - mode_vector: switching modes (0-based)
    time_vector = round(dtSwitch * 1e6);
    mode_vector = Omega - 1;
end
