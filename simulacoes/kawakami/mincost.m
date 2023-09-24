function [Jstar, dtstar, xrecstar] = mincost(Omega)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example 2 in Patino, Riedinger & Ruiz (2010)
E = 30;
C1 = 40e-6;
C2 = 40e-6;
L = 10e-3;
R = 10;
for i = 1:8
    u = dec2bin(i-1,3);
    u1 = str2num(u(1));
    u2 = str2num(u(2));
    u3 = str2num(u(3));
    A{i} = [0 0 (-u1 + u2)/C1;
            0 0 (-u2 + u3)/C2;
            (u1 - u2)/L (u2 - u3)/L -R/L];
    b{i} = [0; 0; (E/L)*u3];
end

save A A
save b b

Q = diag([10 5 20000]);
xref = [E/3; 2*E/3; 1];
Nsim = 100;
% Constraints
dt_min = 0.022e-3;
Tp_max = 0.4e-3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initial guess
s = length(Omega); % Number of switchings
dt0 = ones(s,1)*Tp_max/s; % Equal dwell time for all modes

J = @(dt,A,b,Omega,xref,Q,Nsim) cost(dt,A,b,Omega,xref,Q,Nsim);
% sum(dt) <= Tp_max
% dt >= ones(s,1)*dt_min
% dt <= ones(s,1)*Tp_max
[dtstar,Jstar] = fmincon(@(dt) J(dt,A,b,Omega,xref,Q,Nsim), dt0, ones(1,s), Tp_max, [], [], ones(s,1)*dt_min, ones(s,1)*Tp_max);

[~,xrecstar] = cost(dtstar,A,b,Omega,xref,Q,Nsim);
