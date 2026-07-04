%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = patino.init_sim_1();

%% CONDICOES INICIAIS

%{ 
    RESULTADOS:
    x    : [0.2510512, 0.2500000,]
    dT   : [0.2510512, 0.2500000,]
    Ts   : [0.0000000, 0.2510512, 0.5010512,]
    fval : 0.0052677
    xend ultimo ciclo: 1.870801, -1.119853
%}

config.x0 = [1.8708 -1.1199];
config.Ts = [0 0.2515 0.5015];
config.Tr = config.Ts;

%% CONSTRUINDO MPC
tr = config.Ts(2:end);
ur = [1, 0];
dtr  = diff(config.Ts);

[Phi, Gamma] = mpc.construcao_modelo_instantes(config.Ac,config.Bc,tr,ur);


N = numel(tr);
p = N - 1;

Q  = diag([10,1]);
R  = eye(p);
Np = 2;

t_on  = 0.25;
t_off = 0.25;

c  = [
    -dtr(1) + t_on;
    -dtr(2) + t_off;
];

[H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = ...
    mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);

%%
% --------------------------------------
% SIMULACAO COMPLETA
% -------------------------------------- 

nsim = 35;

c = config;

c.mpc          = struct();
c.mpc.on       = 1;

c.mpc.x_target = [1.8708 -1.1199];
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


c.x0 = c.x0 + [0.1, 0.5];
[y,t,u] = patino.sim_n(c, nsim);


figure(2);
clf();
hold on;

plot(y(:,1), y(:,2));
plot(c.xref(1), c.xref(2), '+', 'linew', 2, 'markersize', 10, 'color', patino.CORES.VERMELHO);

% ultimo ciclo
c    = config;
c.x0 = y(end,:);
yend = patino.sim_1(c);

plot(yend(:,1), yend(:,2), 'k', 'linew', 2);
axis equal;
fprintf('xend ultimo ciclo: %.6f, %.6f\n', c.x0(1), c.x0(2));
grid on;

figure(3)
clf();
zz_plot();
