

% Phi
%   1, 6
%   0, 1

% Gamma
%   4, 3, -1
%   1, 1, -1

clear mpc;

bla = load('bla.mat');
config = bla.config;
tr = bla.tr;
xr = bla.xr;


[Phi, Gamma] = mpc.construcao_modelo_instantes(config.A, config.b, tr, xr, config)