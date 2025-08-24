
function z_create_lookup()
    s = start();
    
    assignin('base', 's', s);

    set_alpha(s, 0.3);
    print_data(s);
end

function print_data(s)
    k = s.get_gain_k();
    
    [rows, cols] = size(k);
    k_str = arrayfun(@num2str, k(:), "UniformOutput", false);
    k_msg = strjoin(k_str, ", ");

    time_us = s.get_time_us();
    [d4, d5, d6] = s.get_mode_bin();

    % signal
    % time_us_str = strjoin(time_us, ",", "UniformOutput", false);
    % d4_str = strjoin(d4, ",", "UniformOutput", false);
    % d5_str = strjoin(d5, ",", "UniformOutput", false);
    % d6_str = strjoin(d6, ",", "UniformOutput", false);
    
    len = numel(time_us);
    fprintf("\n\n");
    for i = 1:len
        fprintf("data_set.time_vec[%d] = %d;\n", i-1, time_us(i));
    end
    for i = 1:len
        fprintf("data_set.d4_vec[%d] = %d;\n", i-1, d4(i));
    end
    for i = 1:len
        fprintf("data_set.d5_vec[%d] = %d;\n", i-1, d5(i));
    end
    for i = 1:len
        fprintf("data_set.d6_vec[%d] = %d;\n", i-1, d6(i));
    end

    fprintf("\n\n");

    % data_set.time_vec = 
    % data_set.d4 = strjoin(d4, ",", "UniformOutput", false);
    
    fprintf("data_set.gain_k.rows = %d;\n", rows);
    fprintf("data_set.gain_k.cols = %d;\n", cols);
    fprintf("data_set.gain_k.size = %d;\n", rows*cols);
    for i = 1:numel(k)
        fprintf("data_set.gain_k.values[%d] = %.7f;\n", i-1, k(i));
    end
    
    mm = s.get_msg_control_signal();
    disp(mm);

end

function set_alpha(s, alpha)
    s.set_traj_phase_with_alpha(alpha);
    s.set_mpc();
end

function s = start()
    s = Simulation();
    s.set_config(Enums.SimName.LAB_CIRCUIT);

    mpc_config = s.get_mpc_config();
    mpc_config.Nd = 15;
    mpc_config.Np = 1; % Nd - Number of delays in the block (repeated control)

    s.set_mpc_config(mpc_config);
end