function var_out = play_patino1(save_fig)
    if (nargin == 0)
        save_fig = false;
    end

    % 1 INIT
    s = Simulation(Enums.SimName.PATINO_1);

    % add constraints
    s.m_config.c_time = [0.25, 0.25];

    % 2 CONSTRUINDO MPC
    mpc = Options.Mpc();
    mpc.Nd = 1;
    mpc.Np = 2;
    mpc.Q  = diag([10, 1]);
    
    s.set_mpc(mpc);
    
    % Instantiating the MPC controller
    controller = Controllers.MpcController(s.m_config.mpc);
    s.set_controller(controller);
    
    

    % 3 RODANDO SIMULACAO
    nsim = 40;
    
    % Store the nominal equilibrium state for the projection center
    x0_nominal = s.m_config.x0;
    
    % Perturbing the state for the simulation initial condition
    % Adjusted back to [0.2; 0.5] from [1.2; 0.5] to match original trajectory
    x0_pertubed = s.m_config.x0 + [0.2; 0.5];

    % Set the StepStrategy to Dense to generate the continuous trajectory like lsim
    s.set_step_strategy(Dynamics.DenseStrategy());

    % simulacao sem controle mpc
s.set_control_enabled(false);
    s.m_config.x0 = x0_pertubed;
    [y_off, t_off, m_off] = s.run(nsim);

    % simulacao com controle mpc
s.set_control_enabled(true);
    s.m_config.x0 = x0_pertubed;
    [y, t, m] = s.run(nsim);

    var_out = Utils.getAllVars();

    % 4 PLOT DOS RESULTADOS
    f1 = figure(1);
    plot_traj(y_off, y, x0_nominal, "Buck-Boost Converter MPC", "x_1 - Voltage Capacitor C", "x_2 - Current Inductor L");

    f2 = figure(2);
    cycles = 10;
    t_limit = cycles * s.m_config.Ts(end);
    plot_u_signal(t_off, m_off, t, m, t_limit);

    f3 = figure(3);
    plot_xi(t_off, y_off, t, y);

    % 5 PROJECAO DA REGIAO DE FACTIBILIDADE
    % Use the same values that matched in z_test_final
    s.m_config.Ts = [0, 0.05, 0.10]; 
    s.m_config.c_time = [0.05, 0.04];
    s.project_feasibility_region([1, 2, 4]);
    hold on;
    % Plot trajectory on top of projection
    plot(y(:,1), y(:,2), 'k', 'LineWidth', 2.5, 'DisplayName', 'Trajetória MPC');
    legend('show');
    hold off;

    if (save_fig)
        addr = 'outputs';
        save_figure(f1, 'patino1_traj', addr);
        save_figure(f2, 'patino1_control', addr);
        save_figure(f3, 'patino1_xi', addr);
        save_figure(f4, 'patino1_feasibility_projection', addr);
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

function plot_u_signal(t_off, m_off, t, m, t_limit)
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

    if nargin >= 5 && ~isempty(t_limit)
        xlim([0, t_limit]);
    end

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
