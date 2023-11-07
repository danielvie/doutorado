%% construindo MPC
% montando valores de referencia
tr  = config.Ts(2:end);
ur  = [1, 0];
dtr = diff(config.Ts);
xr  = engine.get_xr(config);

[Phi, Gamma] = mpc.construcao_modelo_instantes(config.Ac, config.Bc, tr, xr, config);

A = config.Ac;
b = config.Bc;
Omega = config.modes + 1;
xbar0 = xr(1,:)';
Dt = diff(config.Ts);

%[Phi,Gamma] = linModel(A,b,Omega,xbar0,Dt);


% Gamma = [Gamma, Gamma_(:, end)];

N  = numel(tr);

p  = N - 1;
Q  = diag([1,1,1]); % FIXME: colocar numel generico
R  = eye(p);
Np = 2; % numero de ciclos a frente

% parametros das restricoes de chaveamento
t_min = 20*1e-6;

c = [
    -dtr(1) + t_min;
    -dtr(2) + t_min;
    -dtr(3) + t_min;
    -dtr(4) + t_min;
    -dtr(5) + t_min;
    -dtr(6) + t_min;
    -dtr(7) + t_min;
    -dtr(8) + t_min;
    -dtr(9) + t_min;
]; % dimensao: Nx1

[H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = ...
    mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);

% criando estrutura com dados MPC
mpc          = struct();
mpc.on       = true;

mpc.x_target = config.x0;
mpc.H        = H;
mpc.Hf       = Hf;
mpc.Phi1Np   = Phi1Np;
mpc.Qbar     = Qbar;
mpc.Rbar     = Rbar;
mpc.Lbar     = Lbar;
mpc.cbar     = cbar;
mpc.Pf       = Pf;
mpc.Sf       = Sf;
mpc.bf       = bf;
mpc.PhiNp    = PhiNp;
mpc.p        = p;

mpc.options  = optimoptions('quadprog', 'Algorithm', 'active-set');
config.mpc   = mpc;