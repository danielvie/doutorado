function res = patino2_phase(save_fig, nsim_in)
    if (nargin == 0)
        save_fig = false;
    end
    
    nsim = 100;
    if (nargin >= 1)
        nsim = nsim_in;
    end


    % get configuration
    config = engine.get_config_sim_patino_2();


    %% CALCULO DA TRAJETORIA

    %% rodando simulacao como resultado da trajetoria
    param = struct();

    param.E = 30;
    param.C(1) = 40e-6;
    param.C(2) = 40e-6;
    param.L = 10*1e-3;
    param.R = 10;

    param.iMax = param.E/param.R; 
    param.iLref = 2.99;
    param.alpha = param.iLref / param.iMax; % Duty cycle

    param.n = 3; % Number of switching cells
    param.T = 0.28*1e-3;

    [Omega,dT] = phase_shift.industrial_solution(param.alpha,param.n,param.T);
    % [A,b] = phase_shift.modelSwitchedCapacitor(param.n,param.R,param.L,param.C,param.E);
    
    config.Omega = Omega;

    cfg = config;
    cfg.Ts = engine.get_ts(dT);
    cfg.x0 = engine.get_x0(cfg);
    
    nsim = 40;

    % save `config` in WS
    assignin('base', "config", config);
    assignin('base', "cfg", cfg);


    % cfg.x0 = cfg.x0 + [4.5; 1.1; 3.1];
    % cfg.x0 = [0.0, 0.0, 0.0];
    % cfg.x0 = [19.2928,9.9247,0.9823];
    % cfg.x0 = [7.6113, 20.8227, 0.0317];


    % config_.x0 = x0;
    % [y,t,u] = sim_1(config_);

    [y, t, m] = engine.sim_n2(cfg, nsim);

    % getting vars from the function
    vout = utils.getAllVars();
    res = resultados.ResPatino2_phase(vout);

    % plot dos resultados
    f1 = figure(1);
    res.plot_xi();

    f2 = figure(2);
    res.plot_traj();

    f3 = figure(3);
    res.plot_u_signal();
    
    res.data.f1 = f1;
    res.data.f2 = f2;
    res.data.f3 = f3;

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


