
function z_create_lookup()
    clc;
    s = start();
    
    assignin('base', 's', s);

    % for i = 1
    for i = 1:9
        alpha = i/10;
        set_alpha(s, alpha);

        sprintf("\n\n\n");
        space = "    ";

        fprintf("%s", space);
        fprintf("if (helper_eql_float(alpha, %.1f)) {\n", alpha);

        fprintf("%s", space);
        fprintf("%s", space);
        fprintf("// alpha: %.1f\n\n", alpha);
        print_data(s, space);
    end
end

function print_data(s, space)

    fprintf("dataset->time_vec.clear();");
    fprintf("dataset->d4_vec.clear();");
    fprintf("dataset->d5_vec.clear();");
    fprintf("dataset->d6_vec.clear();");
    fprintf("dataset->target.clear();");

    k = s.get_gain_k();
    
    [rows, cols] = size(k);

    time_us = s.get_time_us();
    [d4, d5, d6] = s.get_mode_bin();
    target = s.get_target();

    len = numel(time_us);
    for i = 1:len
        fprintf("%s", space);
        fprintf("%s", space);
        fprintf("dataset->time_vec[%d] = %d;\n", i-1, time_us(i));
    end
    for i = 1:len
        fprintf("%s", space);
        fprintf("%s", space);
        fprintf("dataset->d4_vec[%d] = %d;\n", i-1, d4(i));
    end
    for i = 1:len
        fprintf("%s", space);
        fprintf("%s", space);
        fprintf("dataset->d5_vec[%d] = %d;\n", i-1, d5(i));
    end
    for i = 1:len
        fprintf("%s", space);
        fprintf("%s", space);
        fprintf("dataset->d6_vec[%d] = %d;\n", i-1, d6(i));
    end
    for i = 1:numel(target)
        fprintf("%s", space);
        fprintf("%s", space);
        fprintf("dataset->target[%d] = %f;\n", i-1, target(i));
    end

    fprintf("\n");
    
    fprintf("%s", space);
    fprintf("%s", space);
    fprintf("dataset->gain_k.rows = %d;\n", rows);
    fprintf("%s", space);
    fprintf("%s", space);
    fprintf("dataset->gain_k.cols = %d;\n", cols);
    fprintf("%s", space);
    fprintf("%s", space);
    fprintf("dataset->gain_k.size = %d;\n", rows*cols);


    kk = k';
    for i = 1:numel(kk)
        fprintf("%s", space);
        fprintf("%s", space);
        fprintf("dataset->gain_k.values[%d] = %.7f;\n", i-1, kk(i));
    end
    fprintf("%s", space);
    fprintf("}\n")

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