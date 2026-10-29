clear, clc, close all

Omega = [0 1 3 7 2 0 4 7 4] + 1; % Paper

[Jstar, dtstar, xrecstar] = mincost(Omega); 

subplot(3,1,1),plot(xrecstar(1,:)), hold on
h = line([0 900],[10 10]); set(h,'Color','k','LineStyle','--')
legend('x_1 = v_{C1} (V)','Setpoint (V)')

subplot(3,1,2),plot(xrecstar(2,:)), hold on
h = line([0 900],[20 20]); set(h,'Color','k','LineStyle','--')
legend('x_2 = v_{C2} (V)','Setpoint (V)'),

subplot(3,1,3),plot(xrecstar(3,:)), hold on
h = line([0 900],[1 1]); set(h,'Color','k','LineStyle','--')
legend('x_3 = i_L (A)','Setpoint (A)'),
xlabel('Time index')