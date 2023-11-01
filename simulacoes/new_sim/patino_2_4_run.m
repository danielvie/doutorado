%% rodando simulacao como resultado da trajetoria


% bla = load('bla.mat');
% config = bla.config;

cfg = config;

cfg.mpc.on = true;


nsim = 50;

% estados
% 1. vc1
% 2. vc2
% 3. i

cfg.x0  = config.x0 + [-2;1;-1];
% cfg.x0 = config.x0 + [0.5; 1.1; 3.1];
% cfg.x0 = [0.0, 0.0, 0.0];
% cfg.x0 = [19.2928,9.9247,0.9823];


% config_.x0 = x0;
% [y,t,u] = sim_1(config_);

[y,t,u,m,dtk_out] = engine.sim_n(cfg, nsim);

