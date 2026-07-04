% aula 8


% a projecao pode ser realizada empregando a funcao 'projection' do MPT Toolbox
% {aula8, slide 33}


% sendo Sf, bf obtidos na caracterizacao de O_inf com os valores de equilibrio xbar, ubar considerados
% {aula8, slide 10}


% modelo discretizado com T = 0.1s

config.A = [1, 0.1; 0, 1];
config.B = [5*1e-3;0.1];
config.C = [1, 0];

% ganho de realimentacao K usando DLQR
config.Q = [50, 0; 0, 1];
config.R = 1;
config.Pf = diag([1, 1]);

% restricoes
config.Sx = [1, 0; -1, 0];
config.bx = [4*pi/6; pi/6];
config.Su = [1;-1];
config.bu = [5; 2];

%config.N = 10;

v = create_projection(config);

plot(v.D);