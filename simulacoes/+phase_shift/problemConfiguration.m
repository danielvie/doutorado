% Flying capacitor DC-DC converter
clear, clc, close all

% Physical parameters

% % Patino et al. (2010)
% E = 30;
% C1 = 40e-6;
% C2 = 40e-6;
% L = 10e-3;
% R = 10;
% T = 0.3e-3; % Approximately the value optimized by Patino et al. (2010)

% Benmiloud et al. (2016)
E = 30;
C(1) = 720e-6;
C(2) = 720e-6;
L = 1;
R = 150;
iMax = E/R; 
iLref = 0.12;
alpha = iLref / iMax; % Duty cycle

n = 3; % Number of switching cells
T = 1/125; % 125 Hz

% Number of subintervals employed for simulation within each interval
% between switchings
Nsim = 100; 

% Industrial solution: Phase shifted modulation
[Omega,dt] = phase_shift.industrial_solution(alpha,n,T)
[A,b] = phase_shift.modelSwitchedCapacitor(n,R,L,C,E);

problemConfig.A = A;
problemConfig.b = b;
problemConfig.iLref = iLref;
problemConfig.Nsim = Nsim;