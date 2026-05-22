function [u3High, u3Low ,u2High, u2Low ,u1High, u1Low, u] = signal_generate(time_us, mode, t_s)

    % convert time to us
    t_us = t_s*1e6;

    % time_us contains the duration of each mode in one complete cycle.
    cycle_time = sum(time_us);
    t_cycle = mod(t_us, cycle_time);

    % Find which interval of the repeating cycle contains the current time.
    time_end = cumsum(time_us);
    idx = find(t_cycle < time_end, 1, 'first');

    dead_time_us = 2;

    % Convert the active mode to 3 binary bits: [U3 U2 U1].
    mode_bin = dec2bin(mode(idx), 3) - '0';

    u1 = mode_bin(3);
    u2 = mode_bin(2);
    u3 = mode_bin(1);

    % Reconstruct the active mode from the output bits.
    u = u1 + 2*u2 + 4*u3;

    % Dead-time switching layer:
    % At each segment boundary, compare the target mode with the previous
    % segment mode. Only channels that change state enter dead time; during
    % this window both complementary outputs for that channel are disabled.
    % The first segment compares against the final segment to protect the
    % wraparound edge of the repeating waveform.
    if idx == 1
        segment_start_us = 0;
        previous_idx = length(mode);
    else
        segment_start_us = time_end(idx - 1);
        previous_idx = idx - 1;
    end

    previous_mode_bin = dec2bin(mode(previous_idx), 3) - '0';
    channel_changed = mode_bin ~= previous_mode_bin;
    in_dead_time = (t_cycle - segment_start_us) < dead_time_us;

    % Creating High/Low signals [-1,1]. A changed channel is forced to
    % [-1, -1] during dead time; otherwise exactly one side is enabled.
    u3High = u3*2 - 1;
    u3Low  = (1-u3)*2 - 1;
    u2High = u2*2 - 1;
    u2Low  = (1-u2)*2 - 1;
    u1High = u1*2 - 1;
    u1Low  = (1-u1)*2 - 1;

    if in_dead_time
        if channel_changed(1)
            u3High = -1;
            u3Low = -1;
        end
        if channel_changed(2)
            u2High = -1;
            u2Low = -1;
        end
        if channel_changed(3)
            u1High = -1;
            u1Low = -1;
        end
    end

end
