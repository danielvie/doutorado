function res = patino2_phase_mpc(save_fig, nsim_in)
    if (nargin == 0)
        save_fig = false;
    end
    
    nsim = 100;
    if (nargin >= 1)
        nsim = nsim_in;
    end


    % get configuration of the system
    config = engine.get_config_sim_patino_2();
    iref = 0.8; 
    % TODO: colocar `iref` com get_config...

    % compute trajectory and MPC parameters
    cfg = compute_phase(config, iref);

    % save results in workspace
    assignin('base', "config", config);
    assignin('base', "cfg", cfg);

    nsim = 40;

    %% SIMULACAO

    % add error in initial condition
    cfg.x0 = cfg.x0 + [2.5; -2.3; 1.1];
    % cfg.x0 = [0.0, 0.0, 0.0];
    % cfg.x0 = [19.2928,9.9247,0.9823];
    % cfg.x0 = [7.6113, 20.8227, 0.0317];


    % config_.x0 = x0;
    % [y,t,u] = sim_1(config_);

    cfg.mpc.on = true;
    [y, t, m] = engine.sim_n2(cfg, nsim);
    
    cfg.mpc.on = false;
    [y_off, t_off, m_off] = engine.sim_n2(cfg, nsim);

    % getting vars from the function
    vout = utils.getAllVars();
    res = resultados.ResPatino2(vout);

    % plot dos resultados
    f1 = figure(1);
    res.plot_xi();

    f2 = figure(2);
    res.plot_traj();

    % f3 = figure(3);
    % res.plot_u_signal();
    
    % res.data.f1 = f1;
    % res.data.f2 = f2;
%     res.data.f3 = f3;

    if (save_fig)
        fprintf("salvando figuras\n\n");

        addr = "../LATEX_tese/Cap2/fig/";
        % saving figures

        config.fig_width = 8;
        config.fig_height = 10;
        save_figure(f1, "graf_patino2_xi.pdf", addr, config);
        save_figure(f2, "graf_patino2_traj.pdf", addr);
        save_figure(f3, "graf_patino2_u_signal.pdf", addr);

        %% copy figures to latex
        % copyfile('graf_ex2_*.pdf', "../../LATEX_tese/Cap2/fig/");
    end

end


