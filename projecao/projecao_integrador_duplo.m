% modelo discretizado com T = 0.1s

config.A = [0, 1; 0, 0];
config.B = [0; 1];
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