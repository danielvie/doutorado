
% PROJECAO PATINO 2

% modelo de predicao:
%{
    e(tn) = Phi e(t0) + Gamma * dt
    Phi -> A
    Gamma -> B7
    dt -> u
%}

Phi   = [ 0.9994663      0.0019766     -0.1457479
         -0.0021148      0.9999105      0.0004491
         -0.0004916     -0.0002995      0.7483118
        ];

Gamma =  [
             0.0096995  -2.4073879   2.4891683  -2.6175142   2.4800831   2.7168026  -2.3438879   2.3440669
            -2.5858563   2.4821412   0.0423572   2.3991777  -2.6053964   0           0           0
            -0.0801513  -0.0778152  -0.0746703   0.1687969   0.1013462  -0.0871122  -0.1889175   0.2000848
        ] * 1e4;

% modelo discretizado com T = 0.1s

config.A = Phi;
config.B = Gamma;

% ganho de realimentacao K usando DLQR
numel_x  = size(Phi, 2);
numel_u  = size(Gamma,2);

config.Q = diag(numel_x);
config.R = diag(size(Gamma,2));

% restricoes

%{
    L dt >= c 
%}

L = toeplitz([1, -1, 0, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0, 0]);

c = [
  -0.4283468
  -0.0440331
  -0.0457114
  -0.0269667
  -0.0276615
  -0.3903555
  -0.0515941
  -0.0676511
  -0.0241833
] * 1e-4;


config.Sx = zeros(1, numel_x);
config.bx = 0;

config.Su = -L;
config.bu = -c;

config.N = 1;


config.xbar = [9.501818346682835; 19.837826908429342;  1.034416863494762];
config.ubar = zeros(numel_u, 1);


v = create_projection(config);

clf;
plot(v.D);
txt = sprintf("projecao patino 2 N:%d", config.N);
title(txt)