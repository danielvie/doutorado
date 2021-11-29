%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = engine.init_sim_patino_1();

%% CONDICOES INICIAIS
config.x0   = [1.8662830; -1.1178948,];
config.Ts   = [0.0000000, 0.2510512, 0.5010512,];
% config.Xr   = reshape([1.8662830,  2.1173230,  1.8662811, -1.1178948, -0.8697124, -1.1178922,],[3  2]);
config.Xr   = engine.get_xr(config);
% Xr_ = sim.get_xr(config);

%% CONSTRUINDO MPC
tr  = config.Ts(2:end);
ur  = [1, 0];
dtr = diff(config.Ts);
xr  = config.Xr;

[Phi, Gamma] = mpc.construcao_modelo_instantes(config.Ac,config.Bc,tr,xr);

N  = numel(tr);
p  = N - 1;

Q  = diag([10,1]);
R  = eye(p);
Np = 2;

% The switch has a dwell time tmin = 0.25s.
t_on  = 0.25;
t_off = 0.25;

c  = [
    -dtr(1) + t_on;
    -dtr(2) + t_off;
];

[H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = ...
    mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);

nsim = 35;

c = config;

c.mpc          = struct();
c.mpc.on       = 1;

c.mpc.x_target = config.x0;
c.mpc.H        = H;
c.mpc.Hf       = Hf;
c.mpc.Phi1Np   = Phi1Np;
c.mpc.Qbar     = Qbar;
c.mpc.Rbar     = Rbar;
c.mpc.Lbar     = Lbar;
c.mpc.cbar     = cbar;
c.mpc.Pf       = Pf;
c.mpc.Sf       = Sf;
c.mpc.bf       = bf;
c.mpc.PhiNp    = PhiNp;
c.mpc.p        = p;

%% RODANDO SIMULACAO
c.x0 = c.x0 + [0.1; 0.5];

c.mpc.on = 0;
[y_,t_,u_,~] = engine.sim_n(c, nsim);
c.mpc.on = 1;
[y,t,u,~, dtk] = engine.sim_n(c, nsim);

figure(2);
clf();
hold on;

plot(y(:,1), y(:,2));
plot(c.xref(1), c.xref(2), '+', 'linew', 2, 'markersize', 10, 'color', engine.CORES.VERMELHO);

% ultimo ciclo
c    = config;
c.x0 = y(end,:);
yend = engine.sim_1(c);

plot(yend(:,1), yend(:,2), 'k', 'linew', 2);
axis equal;
fprintf('xend ultimo ciclo: %.6f, %.6f\n', c.x0(1), c.x0(2));
grid on;

% figure(3)
% clf();
% zz_plot();
