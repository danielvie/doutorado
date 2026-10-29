function problemConfiguration(opt)

    if nargin == 0
        opt = 2;
    end

    % Flying capacitor DC-DC converter
    % clear, clc, close all

    % Physical parameters

    % % Patino et al. (2010)
    % E = 30;
    % C1 = 40e-6;
    % C2 = 40e-6;
    % L = 10e-3;
    % R = 10;
    % T = 0.3e-3; % Approximately the value optimized by Patino et al. (2010)

    % Benmiloud et al. (2016)
    param_1 = struct();
    param_1.E = 30;
    param_1.C(1) = 720e-6;
    param_1.C(2) = 720e-6;
    param_1.L = 1;
    param_1.R = 150;

    param_1.iMax = param_1.E/param_1.R; 
    param_1.iLref = 0.12;
    param_1.alpha = param_1.iLref / param_1.iMax; % Duty cycle

    param_1.n = 3; % Number of switching cells
    param_1.T = 1/125; % 125 Hz

    % Patino 2
    param_2 = struct();
    param_2.E = 30;
    param_2.C(1) = 40e-6;
    param_2.C(2) = 40e-6;
    param_2.L = 10;
    param_2.R = 10;

    param_2.iMax = param_2.E/param_2.R; 
    param_2.iLref = 0.12;
    param_2.alpha = param_2.iLref / param_2.iMax; % Duty cycle

    param_2.n = 3; % Number of switching cells
    param_2.T = 0.4*1e-3;





    % Number of subintervals employed for simulation within each interval
    % between switchings
    Nsim = 100; 

    % Industrial solution: Phase shifted modulation
    if opt == 1
        p = param_1;
    else
        p = param_2;
    end

    [Omega,dt] = phase_shift.industrial_solution(p.alpha,p.n,p.T)
    % [A,b] = phase_shift.modelSwitchedCapacitor(n,R,L,C,E);

    % problemConfig.A = A;
    % problemConfig.b = b;
    % problemConfig.iLref = iLref;
    % problemConfig.Nsim = Nsim;
    
    assignin('base', 'Omega', Omega);
    assignin('base', 'dt', dt);

end