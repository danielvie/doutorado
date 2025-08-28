
function z_create_lookup()
    clc;
    s = start();
    
    assignin('base', 's', s);
    
    message = "void helper_set_dataset_from_alpha(DataSet *dataset, const float alpha) {";
    message = sprintf("%s\n", message);

    % for i = 1
    for i = 1:9
        alpha = i/10;
        set_alpha(s, alpha);

        message = tab(message, 1);
        message = sprintf("%sif (helper_eql_float(alpha, %.1f)) {\n", message, alpha);

        message = tab(message, 2);
        message = sprintf("%s// alpha: %.1f\n\n", message, alpha);
        message = print_data(message, s);
    end
    clc;
    
    message = sprintf("%s}\n", message);

    disp(message);
    clipboard('copy', message);
end

function message = tab(message, n)
    for i = 1:n
        message = sprintf("%s    ", message);
    end
end

function message = print_data(message_in, s)

    message = message_in;
    
    k = s.get_gain_k();
    
    [rows, cols] = size(k);

    time_us = s.get_time_us();
    [d6, d5, d4] = s.get_mode_bin();
    target = s.get_target();

    len = numel(time_us);

    message = tab(message, 2);
    message = sprintf("%sdataset->size_vec = %d;\n", message, len);
    for i = 1:len
        message = tab(message, 2);
        message = sprintf("%sdataset->time_vec[%d] = %d;\n", message, i-1, time_us(i));
    end
    for i = 1:len
        message = tab(message, 2);
        message = sprintf("%sdataset->d4_vec[%d] = %d;\n", message, i-1, d4(i));
    end
    for i = 1:len
        message = tab(message, 2);
        message = sprintf("%sdataset->d5_vec[%d] = %d;\n", message, i-1, d5(i));
    end
    for i = 1:len
        message = tab(message, 2);
        message = sprintf("%sdataset->d6_vec[%d] = %d;\n", message, i-1, d6(i));
    end
    for i = 1:numel(target)
        message = tab(message, 2);
        message = sprintf("%sdataset->target[%d] = %f;\n", message, i-1, target(i));
    end

    message = sprintf("%s\n", message);
    
    message = tab(message, 2);
    message = sprintf("%sdataset->gain_k.rows = %d;\n", message, rows);
    message = tab(message, 2);
    message = sprintf("%sdataset->gain_k.cols = %d;\n", message, cols);
    message = tab(message, 2);
    message = sprintf("%sdataset->gain_k.size = %d;\n", message, rows*cols);


    kk = k';
    for i = 1:numel(kk)
        message = tab(message, 2);
        message = sprintf("%sdataset->gain_k.values[%d] = %.7f;\n", message, i-1, kk(i));
    end
    message = tab(message, 1);
    message = sprintf("%s}\n", message);

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