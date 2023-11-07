%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = engine.get_config_sim_matheus();

%% CONDICOES INICIAIS


% xr = [-0.5, -1.0
%       -0.5,  1.0
%        0.5,  1.0
%        0.5, -1.0
%       -0.5, -1.0];

xr = engine.get_xr(config);

%% CONSTRUINDO MPC

tr = config.Ts(2:end);
[Phi, Gamma] = mpc.construcao_modelo_instantes(config.Ac,config.Bc,tr,xr);

N  = numel(tr);
p  = N - 1;

Q  = eye(2);
R  = eye(p);
Np = 1;

t_on  = 1.625;
t_off = 0.625;

dtr = diff(config.Ts);
c  = [
    -dtr(1) + t_on;
    -dtr(2) + t_off;
    -dtr(3) + t_on;
    -dtr(4) + t_off;
];

[H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = ...
    mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);

config.mpc          = struct();
config.mpc.on       = 1;

config.mpc.x_target = config.x0;
config.mpc.H        = H;
config.mpc.Hf       = Hf;
config.mpc.Phi1Np   = Phi1Np;
config.mpc.Qbar     = Qbar;
config.mpc.Rbar     = Rbar;
config.mpc.Lbar     = Lbar;
config.mpc.cbar     = cbar;
config.mpc.Pf       = Pf;
config.mpc.Sf       = Sf;
config.mpc.bf       = bf;
config.mpc.PhiNp    = PhiNp;
config.mpc.p        = p;

%% RODANDO SIMULACAO
nsim      = 30;

config.x0 = config.x0 + [-1; .5];
[y,t,u,m] = engine.sim_n(config, nsim);




plot(y(:,1), y(:,2));
grid on;
hold on;
plot(y(1,1), y(1,2), 'ro');
hold off;

