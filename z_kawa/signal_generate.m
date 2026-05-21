function [u3High, u3Low ,u2High, u2Low ,u1High, u1Low, u] = signal_generate(time_us, mode, t_s)

    t_us = t_s*1e6;

    % time_us contains the duration of each mode in one complete cycle.
    cycle_time = sum(time_us);
    t_cycle = mod(t_us, cycle_time);

    % Find which interval of the repeating cycle contains the current time.
    time_end = cumsum(time_us);
    idx = find(t_cycle < time_end, 1, 'first');

    % Convert the active mode to 3 binary bits: [MSB ... LSB].
    mode_bin = dec2bin(mode(idx), 3) - '0';

    u1 = mode_bin(3);
    u2 = mode_bin(2);
    u3 = mode_bin(1);

    % Reconstruct the active mode from the output bits.
    u = u1 + 2*u2 + 4*u3;

    % Creating High/Low signals
    u3High = u3*2 - 1;
    u3Low  = (1-u3)*2 - 1;
    u2High = u2*2 - 1;
    u2Low  = (1-u2)*2 - 1;
    u1High = u1*2 - 1;
    u1Low  = (1-u1)*2 - 1;



end
