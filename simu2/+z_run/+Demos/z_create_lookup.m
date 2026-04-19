
function z_create_lookup()
    clc;
    s = start();
    
    assignin('base', 's', s);

    % header
    message = sprintf("// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.\n\n");
    message = sprintf("%s#include ""helper_datasetter.h""\n\n", message);
    message = sprintf("%sstatic const float TOL = 0.001;\n", message);
    message = sprintf("%sbool helper_eql_float(const float a, const float b) {\n", message);
    message = sprintf("%s    return std::fabs(a - b) < TOL;\n", message);
    
    message = sprintf("%s}\n\n", message);

    message = sprintf("%svoid helper_set_dataset_from_alpha(DataSet *dataset, const float alpha) {\n", message);
    message = sprintf("%s\n", message);

    str_else = "";
    % for i = 1:3
    for i = 10:90
        alpha = i/100;
        set_alpha(s, alpha);

        message = tab(message, 1);
        message = sprintf("%s%sif (helper_eql_float(alpha, %.2f)) {\n", message, str_else, alpha);

        message = tab(message, 2);
        message = sprintf("%s// alpha: %.2f\n\n", message, alpha);
        message = print_data(message, s);
        
        if strcmp(str_else, "")
            str_else = "else ";
        end
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
    
    % not accept time less than 4 us
    time_us = max(time_us, 7);

    [d6, d5, d4] = s.get_mode_bin();
    target = s.get_target();

    len = numel(time_us);

    message = tab(message, 2);
    message = sprintf("%sdataset->size = %d;\n", message, len);
    for i = 1:len
        message = tab(message, 2);
        message = sprintf("%sdataset->time_durations[%d] = %d;\n", message, i-1, time_us(i));
    end
    for i = 1:len
        message = tab(message, 2);
        message = sprintf("%sdataset->modes_d4[%d] = %d;\n", message, i-1, d4(i));
    end
    for i = 1:len
        message = tab(message, 2);
        message = sprintf("%sdataset->modes_d5[%d] = %d;\n", message, i-1, d5(i));
    end
    for i = 1:len
        message = tab(message, 2);
        message = sprintf("%sdataset->modes_d6[%d] = %d;\n", message, i-1, d6(i));
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

    config_mpc = s.get_config_mpc();
    config_mpc.Nd = 15;
    config_mpc.Np = 1; % Nd - Number of delays in the block (repeated control)

    s.set_config_mpc(config_mpc);
end