function [A_block, B_block] = build_blocked_model( ...
    A_cycle, B_cycle, block_length_cycles)
    % Lift a constant input over a block of switching cycles.

    A_block = A_cycle ^ block_length_cycles;
    B_block = zeros(size(B_cycle));
    A_power = eye(size(A_cycle));

    for cycle = 1:block_length_cycles
        B_block = B_block + A_power * B_cycle;
        A_power = A_cycle * A_power;
    end
end
