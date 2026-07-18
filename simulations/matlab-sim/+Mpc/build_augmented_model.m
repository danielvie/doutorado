function [A_delayed, B_delayed] = build_augmented_model( ...
    A_cycle, B_cycle, block_length_cycles)
    % Build the experimental held-input model with one block of delay.

    [A_block, B_block] = Mpc.build_blocked_model( ...
        A_cycle, B_cycle, block_length_cycles);

    state_len = size(A_block, 1);
    action_len = size(B_block, 2);

    A_delayed = [A_block, B_block; ...
        zeros(action_len, state_len), zeros(action_len, action_len)];
    B_delayed = [zeros(state_len, action_len); eye(action_len)];
end
