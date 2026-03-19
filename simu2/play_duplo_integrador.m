function var_out = play_duplo_integrador(save_fig)
    if (nargin == 0)
        save_fig = false;
    end

    % 1 INIT
    s = Simulation(Enums.SimName.INTEGRADOR_DUPLO);

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
    s.m_config.x0 = s.m_config.x0 + [2; 0.5];

    % simulacao sem controle mpc
    s.m_config.mpc.on = false;
    [y_off, t_off, m_off] = s.run(nsim);

    % simulacao com controle mpc
    s.m_config.mpc.on = true;
    [y, t, m] = s.run(nsim);

    % 4 PLOT DOS RESULTADOS
    ncycle = size(y_off, 1) / nsim;

    f1 = figure(1);
    plot_traj(y_off(1:end,:), s.m_config.x0, "double integrator MPC off", "v_c", "i_L");

    f2 = figure(2);
    plot_traj(y, s.m_config.x0, "double integrator MPC on", "v_c", "i_L");

    f3 = figure(3);
    plot_control_signal(t_off, m_off, t, m, "double integrator Control Signal", "time (s)", "mode");

    f4 = figure(4);
    plot_xi(t_off, y_off, t, y);

    % output vars
    var_out = Utils.getAllVars();

    if (save_fig)
        addr = 'outputs';
        save_figure(f1, 'duplo_integrador_traj_off', addr);
        save_figure(f2, 'duplo_integrador_traj_on', addr);
        save_figure(f3, 'duplo_integrador_control', addr);
        save_figure(f4, 'duplo_integrador_xi', addr);
    end
end

function plot_traj(y, x0, tit, x_label, y_label)
    plot(y(:,1), y(:,2), 'linew', 1.2);
    hold on;

    % subplot markers
    plot(y(1,1), y(1,2), 'ro', 'markers', 10, 'linew', 1.2);
    plot(y(end,1), y(end,2), 'k.', 'markers', 30);
    plot(x0(1), x0(2), 'rx', 'linew', 2, 'markers', 16);

    legend('trajectory', 'start', 'end', 'target x_0', 'location', 'southeast');

    hold off;
    grid on;
    axis equal;
    title(tit);
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);
end

function plot_control_signal(t_off, m_off, t, m, tit, x_label, y_label)
    f = stairs(t_off, m_off, 'linew', 2);
    hold on;
    stairs(t, m, 'linew', 2, 'linestyle', '--');
    hold off;
    
    grid on;
    title(tit);
    xlabel(x_label);
    ylabel(y_label);
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
    ylabel('Position (x_1)'); grid on;
    legend('MPC off', 'MPC on');
    title('Double Integrator States');
    set(gca, 'FontSize', 12);

    subplot(2,1,2);
    plot(t_off, y_off(:,2), 'r', 'LineWidth', 1.5); hold on;
    plot(t, y(:,2), 'b--', 'LineWidth', 1.5); hold off;
    ylabel('Velocity (x_2)'); grid on;
    xlabel('Time (s)');
    set(gca, 'FontSize', 12);
end
