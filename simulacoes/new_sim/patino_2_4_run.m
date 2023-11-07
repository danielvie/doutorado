%% rodando simulacao como resultado da trajetoria


% bla = load('bla.mat');
% config = bla.config;

cfg = config;

nsim = 50;

% estados
% 1. vc1
% 2. vc2
% 3. i

% adicionando erros
cfg.x0  = config.x0 + [-2;1;-1];


cfg.mpc.on = true;
[y,t,u,m,dtk_out] = engine.sim_n(cfg, nsim);

cfg.mpc.on = false;
[y_off,t_off,u_off,m_off,dtk_out_off] = engine.sim_n(cfg, nsim);