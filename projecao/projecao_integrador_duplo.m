
% PROJECAO INTEGRADOR DUPLO

% modelo de predicao:
%{
    e(tn) = Phi e(t0) + Gamma * dt
    Phi -> A
    Gamma -> B
    dt -> u
%}


% carregando simulacao integ. duplo em var `s`
load('s', 's');

Phi   = [1, 6; 0, 1];
Gamma = [4, 3, -1; 1, 1, -1];

% modelo discretizado com T = 0.1s


config.A = Phi;
config.B = Gamma;
config.C = [1, 0];

% ganho de realimentacao K usando DLQR
config.Q = diag(ones(2,1));
config.R = 1;
config.Pf = diag([1, 1]);

% restricoes

%{
    L dt <= c 
%}

Ts = [0, 2, 3, 5, 6];
dtr = diff(Ts);

t_on  = 1.625;
t_off = 0.635;

L = toeplitz([1, -1, 0, 0], [1, 0, 0]);

c = [
    -dtr(1) + t_on;
    -dtr(2) + t_off;
    -dtr(3) + t_on;
    -dtr(4) + t_off;
];

config.Sx = [];
config.bx = [];
config.Su = -L;
config.bu = -c;

%config.N = 10;

v = create_projection(config);

plot(v.D);