function var_out = play_patino1(save_fig)
    if (nargin == 0)
        save_fig = false;
    end

    % 1 INIT
    s = Simulation(Enums.SimName.PATINO_1);

    % 2 CONSTRUINDO MPC
    config_mpc = s.get_config_mpc();
    config_mpc.Nd = 1;
    config_mpc.Np = 2;
    config_mpc.Q  = diag([10, 1]);
    
    s.set_config_mpc(config_mpc);
    s.set_mpc();
    
    % Instantiating the MPC controller
    mpc_data = s.m_config.mpc;
    controller = Controllers.MpcController(mpc_data);
    s.set_controller(controller);

    % 3 RODANDO SIMULACAO
    nsim = 40;
    s.m_config.x0 = s.m_config.x0 + [0.2; 0.5];

    % simulacao sem controle mpc
    s.m_config.mpc.on = false;
    [y_off, t_off, m_off] = s.run(nsim);

    % simulacao com controle mpc
    s.m_config.mpc.on = true;
    [y, t, m] = s.run(nsim);

    var_out = Utils.getAllVars();

    % 4 PLOT DOS RESULTADOS
    f1 = figure(1);
    plot_traj(y_off, y, s.m_config.x0, "Patino1 Trajectory", "V_{c} [V]", "I_{L} [A]");

    f2 = figure(2);
    plot_u_signal(t_off, m_off, t, m);

    f3 = figure(3);
    plot_xi(t_off, y_off, t, y);

    if (save_fig)
        addr = 'outputs';
        save_figure(f1, 'patino1_traj', addr);
        save_figure(f2, 'patino1_control', addr);
        save_figure(f3, 'patino1_xi', addr);
    end
end

function plot_traj(y_off, y, x0, tit, x_label, y_label)
    plot(y_off(:,1), y_off(:,2), 'linew', 1.2);
    hold on;
    plot(y(:,1), y(:,2), 'linew', 1.2);

    plot(y(1,1), y(1,2), 'ro', 'markers', 10, 'linew', 1.2);
    plot(y_off(end,1), y_off(end,2), 'k*', 'markers', 15);
    plot(y(end,1), y(end,2), 'k.', 'markers', 30);
    plot(x0(1), x0(2), 'rx', 'linew', 2, 'markers', 16);

    legend('trajectory MPC off', 'trajectory MPC on', 'start', 'end MPC off', 'end MPC on', 'target x_0', 'location', 'southeast');

    hold off;
    grid on;
    title(tit);
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);
end

function plot_u_signal(t_off, m_off, t, m)
    f = stairs(t_off, m_off, 'linew', 2);
    hold on;
    stairs(t, m, 'linew', 2, 'linestyle', '--');
    hold off;
    
    grid on;
    title("Patino1 Control Signal");
    xlabel("time (s)");
    ylabel("mode");
    set(gca,'fontsize', 15);
    legend('modes target trajectory', 'modes simulation');

    v = f.Parent.YTick;
    p = abs(v - floor(v)) < 0.1;
    f.Parent.YTick = v(p);
end

function plot_xi(t_off, y_off, t, y)
    subplot(2,1,1);
    plot(t_off, y_off(:,1), 'r', 'LineWidth', 1.5); hold on;
    plot(t, y(:,1), 'b--', 'LineWidth', 1.5); hold off;
    ylabel('Voltage v_C [V]'); grid on;
    legend('MPC off', 'MPC on');
    title('Patino1 States over Time');
    set(gca, 'FontSize', 12);

    subplot(2,1,2);
    plot(t_off, y_off(:,2), 'r', 'LineWidth', 1.5); hold on;
    plot(t, y(:,2), 'b--', 'LineWidth', 1.5); hold off;
    ylabel('Current i_L [A]'); grid on;
    xlabel('Time (s)');
    set(gca, 'FontSize', 12);
end
