function res = play_patino2(save_fig, nsim_in)
    if (nargin == 0)
        save_fig = false;
    end
    
    nsim = 8;
    if (nargin > 1)
        nsim = nsim_in;
    end

    % 1 INIT
    s = Simulation(Enums.SimName.PATINO_2);

    % 2 CONSTRUINDO MPC
    mpc = Interface.config_mpc();
    mpc.Nd = 1;
    mpc.Np = 2;
    mpc.Q  = diag([1, 1, 1]);
    
    s.set_mpc(mpc);
    
    % Instantiating the MPC controller
    controller_mpc = Controllers.MpcController(s.m_config.mpc);


    K = s.get_gain_k();
    time_us = s.get_time_us();
    controller_prop = Controllers.Proportional(K, 1, time_us, 3*1e-6);

    s.set_controller(controller_mpc);
    

    % 3 RODANDO SIMULACAO
    % O estado inicial nominal (x_target)
    x0_target = s.m_config.x0;
    
    % Aplicando perturbação para forçar os controladores a agir
    % x0_perturbed = x0_target + [-1.2; -1.3; -.9];
    x0_perturbed = [7.51; 20.82; 0.03];


    fprintf("x0: \n");
    disp(x0_target);
    
    fprintf("x0_perturbed: \n");
    disp(x0_perturbed);
    

    % 1. Controle MPC
    s.m_config.mpc.on = true;
    s.m_config.x0 = x0_perturbed;
    s.set_controller(controller_mpc);
    [y_mpc, t_mpc, m_mpc] = s.run(nsim);

    % 2. Controle Proporcional
    s.m_config.mpc.on = true;
    s.m_config.x0 = x0_perturbed;
    s.set_controller(controller_prop);
    [y_prop, t_prop, m_prop] = s.run(nsim);

    % 3. Controle OFF
    s.m_config.mpc.on = false;
    s.m_config.x0 = x0_perturbed;
    s.set_controller(controller_prop);
    [y_off, t_off, m_off] = s.run(nsim);


    var_out = Utils.getAllVars();
    res = var_out;

    % 4 PLOT DOS RESULTADOS
    f1 = figure(1);
    plot_xi_comparison(t_mpc, y_mpc, t_prop, y_prop, 'MPC', 'PROP');

    f2 = figure(2);
    plot_u_signal_comparison(t_off, m_off, t_mpc, m_mpc, 'OFF', 'MPC', 10, nsim);

    f3 = figure(3);
    plot_u_signal_comparison(t_off, m_off, t_prop, m_prop, 'OFF', 'PROP', 10, nsim);

    f4 = figure(4);
    plot_traj_comparison(y_mpc, y_prop, x0_target, 'MPC', 'PROP');

    f5 = figure(5);
    plot_traj_comparison(y_mpc, y_off, x0_target, 'MPC', 'OFF');

    f6 = figure(6);
    plot_traj_comparison(y_prop, y_off, x0_target, 'PROP', 'OFF');

    f7 = figure(7);
    plot_traj_comparison_3(y_mpc, y_prop, y_off, x0_target, 'MPC', 'PROP', 'OFF');


    if (save_fig)
        addr = 'outputs';
        save_figure(f1, 'patino2_xi_mpc_vs_prop', addr);
        save_figure(f2, 'patino2_u_signal_mpc', addr);
        save_figure(f3, 'patino2_u_signal_prop', addr);
        save_figure(f4, 'patino2_traj_mpc_vs_prop', addr);
        save_figure(f5, 'patino2_traj_mpc_vs_off', addr);
        save_figure(f6, 'patino2_traj_prop_vs_off', addr);
        save_figure(f7, 'patino2_traj_mpc_vs_prop_vs_off', addr);
    end
end

function plot_xi_helper(t_mpc, yi_mpc, t_prop, yi_prop, tit, x_label, y_label)
    plot(t_mpc, yi_mpc, 'b', 'linew', 1.2); hold on;
    plot(t_prop, yi_prop, 'r--', 'linew', 1.2); hold off;

    grid on;
    title(tit)
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 14);
end

function plot_xi_comparison(t1, y1, t2, y2, name1, name2)
    if nargin < 6
        name1 = 'Sim 1';
        name2 = 'Sim 2';
    end
    subplot(3,1,1);
    plot_xi_helper(t1, y1(:,1), t2, y2(:,1), 'Voltage C_1', 't [s]', 'V_{c1} [V]')
    legend(name1, name2);
    subplot(3,1,2);
    plot_xi_helper(t1, y1(:,2), t2, y2(:,2), 'Voltage C_2', 't [s]', 'V_{c2} [V]')
    subplot(3,1,3);
    plot_xi_helper(t1, y1(:,3), t2, y2(:,3), 'Current i_L', 't [s]', 'i_{L} [A]')
end

function plot_traj_helper(Y1, Y2, x0, tit, x_label, y_label, z_label, leg)
    plot3(Y1(:,1), Y1(:,2), Y1(:,3), 'b', 'linew', 1.5); hold on;
    plot3(Y2(:,1), Y2(:,2), Y2(:,3), 'r--');

    % markers
    plot3(Y1(1,1), Y1(1,2), Y1(1,3), 'ro', 'markers', 15, 'linew', 2);
    plot3(Y1(end,1), Y1(end,2), Y1(end,3), 'b.', 'markers', 40);
    plot3(Y2(end,1), Y2(end,2), Y2(end,3), 'r*', 'markers', 10);
    plot3(x0(1), x0(2), x0(3), 'rx', 'markers', 25, 'linew', 3);

    legend(leg{:});
    hold off;
    grid on;
    title(tit)
    xlabel(x_label);
    ylabel(y_label);
    zlabel(z_label);
    set(gca,'fontsize', 14);
end

function plot_traj_comparison(y1, y2, x0, name1, name2)
    if nargin < 5
        name1 = 'Sim 1';
        name2 = 'Sim 2';
    end
    tit = sprintf("Multilevel Converter Trajectory: %s vs %s", name1, name2);
    leg = {sprintf('trajectory %s', name1), sprintf('trajectory %s', name2), 'start', sprintf('end %s', name1), sprintf('end %s', name2), 'target x_0', 'location', 'best'};
    plot_traj_helper(y1, y2, x0, tit, "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]", leg);
end

function plot_traj_helper_3(Y1, Y2, Y3, x0, tit, x_label, y_label, z_label, leg)
    plot3(Y1(:,1), Y1(:,2), Y1(:,3), 'b', 'linew', 1.5); hold on;
    plot3(Y2(:,1), Y2(:,2), Y2(:,3), 'r', 'linew', 1.5);
    plot3(Y3(:,1), Y3(:,2), Y3(:,3), 'k:', 'linew', 1.5);

    % markers
    plot3(Y1(1,1), Y1(1,2), Y1(1,3), 'ro', 'markers', 15, 'linew', 2);
    plot3(Y1(end,1), Y1(end,2), Y1(end,3), 'b.', 'markers', 40);
    plot3(Y2(end,1), Y2(end,2), Y2(end,3), 'r*', 'markers', 10);
    plot3(Y3(end,1), Y3(end,2), Y3(end,3), 'ks', 'markers', 10);
    plot3(x0(1), x0(2), x0(3), 'rx', 'markers', 25, 'linew', 3);

    legend(leg{:});
    hold off;
    grid on;
    title(tit)
    xlabel(x_label);
    ylabel(y_label);
    zlabel(z_label);
    set(gca,'fontsize', 14);
end

function plot_traj_comparison_3(y1, y2, y3, x0, name1, name2, name3)
    if nargin < 7
        name1 = 'Sim 1';
        name2 = 'Sim 2';
        name3 = 'Sim 3';
    end
    tit = sprintf("Multilevel Converter Trajectory: %s vs %s vs %s", name1, name2, name3);
    leg = {sprintf('trajectory %s', name1), sprintf('trajectory %s', name2), sprintf('trajectory %s', name3), 'start', sprintf('end %s', name1), sprintf('end %s', name2), sprintf('end %s', name3), 'target x_0', 'location', 'best'};
    plot_traj_helper_3(y1, y2, y3, x0, tit, "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]", leg);
end

function plot_u_signal_comparison(t1, m1, t2, m2, name1, name2, ncycles, total_nsim)
    % determine how many elements to plot (default to 10 cycles if not specified)
    if nargin < 7
        ncycles = 10;
    end
    
    ncycles = min(ncycles, total_nsim);
    
    nelements1 = floor((length(m1) / total_nsim) * ncycles);
    nelements2 = floor((length(m2) / total_nsim) * ncycles);
    
    stairs(t1(1:nelements1), m1(1:nelements1), 'b', 'linew', 1.5); hold on;
    stairs(t2(1:nelements2), m2(1:nelements2), 'r--', 'linew', 1.5);
    hold off;
    
    grid on;
    legend(name1, name2);
    title(sprintf('Control Signal Comparison: %s vs %s', name1, name2));
    xlabel('time (s)');
    ylabel('mode');
    set(gca, 'fontsize', 14);
    
    % integer ticks for Y axis
    ax = gca;
    v = ax.YTick;
    ax.YTick = v(abs(v - round(v)) < 1e-4);
end
