function res = play_patino2(save_fig, nsim_in)
    if (nargin == 0)
        save_fig = false;
    end
    
    nsim = 100;
    if (nargin > 1)
        nsim = nsim_in;
    end

    % 1 INIT
    s = Simulation(Enums.SimName.PATINO_2);

    % 2 CONSTRUINDO MPC
    config_mpc = s.get_config_mpc();
    config_mpc.Nd = 1;
    config_mpc.Np = 2;
    config_mpc.Q  = diag([1, 1, 1]);
    
    s.set_config_mpc(config_mpc);
    s.set_mpc();
    
    % Instantiating the MPC controller
    mpc_data = s.m_config.mpc;
    controller = Controllers.MpcController(mpc_data);
    s.set_controller(controller);

    % 3 RODANDO SIMULACAO
    
    % primeira run mpc=true
    s.m_config.mpc.on = true;
    [y, t, m] = s.run(nsim);

    % mpc=false
    s.m_config.mpc.on = false;
    s.m_config.x0  = s.m_config.x0 + [-1.2; -1.3; -.9];
    [y_off, t_off, m_off] = s.run(nsim);

    % mpc=true (quanti) - em simu2 o run processa normal
    s.m_config.mpc.on = true;
    [y_quant, t_quant, m_quant] = s.run(nsim);

    var_out = Utils.getAllVars();
    res = var_out;

    % 4 PLOT DOS RESULTADOS
    f1 = figure(1);
    plot_xi_quant(t, y, t_quant, y_quant);

    f2 = figure(2);
    plot_traj_quant(y, y_quant, s.m_config.x0);

    if (save_fig)
        addr = 'outputs';
        save_figure(f1, 'patino2_xi_quant', addr);
        save_figure(f2, 'patino2_traj_quant', addr);
    end
end

function plot_xi_helper(t, yi, t_quant, yi_quant, tit, x_label, y_label)
    plot(t, yi); hold on;
    plot(t_quant, yi_quant); hold off;

    grid on;
    title(tit)
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);
end

function plot_xi_quant(t, y, t_quant, y_quant)
    subplot(3,1,1);
    plot_xi_helper(t, y(:,1), t_quant, y_quant(:,1), 'Voltage C_1 Multilevel Converter', 't - time(s)', 'V_{c1} [V]')
    subplot(3,1,2);
    plot_xi_helper(t, y(:,2), t_quant, y_quant(:,2), 'Voltage C_2 Multilevel Converter', 't - time(s)', 'V_{c2} [V]')
    subplot(3,1,3);
    plot_xi_helper(t, y(:,3), t_quant, y_quant(:,3), 'Current i_L Multilevel Converter', 't - time(s)', 'i_{L} [A]')
end

function plot_traj_helper(Y, Y2, x0, tit, x_label, y_label, z_label, leg)
    y1 = Y(:,1); y2 = Y(:,2); y3 = Y(:,3);
    y_1 = Y2(:,1); y_2 = Y2(:,2); y_3 = Y2(:,3);

    plot3(y1, y2, y3); hold on;
    plot3(y_1, y_2, y_3);

    % markers
    plot3(y1(1), y2(1), y3(1), 'ro', 'markers', 15, 'linew', 2);
    plot3(y1(end), y2(end), y3(end), 'k.', 'markers', 50);
    plot3(y_1(end), y_2(end), y_3(end), 'k*', 'markers', 15, 'linew', 2);
    plot3(x0(1), x0(2), x0(3), 'rx', 'markers', 25, 'linew', 3);

    legend(leg{:});
    hold off;
    grid on;
    title(tit)
    xlabel(x_label);
    ylabel(y_label);
    zlabel(z_label);
    set(gca,'fontsize', 15);
end

function plot_traj_quant(y, y_quant, x0)
    leg = {'trajectory MPC', 'trajectory MPC quant', 'start', 'end MPC', 'end MPC quant', 'target x_0', 'location', 'southeast'};
    plot_traj_helper(y, y_quant, x0, "Multilevel Converter Trajectory", "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]", leg);
end
