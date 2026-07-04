%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = doc.init_sim_1();

%%
% --------------------------------------
% PARAMETROS SIMULACAO
% --------------------------------------

% Ts  = [0., 0.2514520, 0.5014520];
% dx1 = 0.0;
% dx2 = 0.0;
% 
% config.Ts    = Ts;
% config.x0    = [1.870801, -1.119853] + [dx1,dx2];
% config.tstep = 1e-4;
% 
% disp('-----------------------------------');
% fprintf('x0: %.6f, %.6f\n', config.x0(1), config.x0(2));
% disp('-----------------------------------');

%%
% --------------------------------------
% FMINCON
% --------------------------------------

figure(1);
clf();
hold on;
grid on;
axis equal;

h = plot(config.xref(1), config.xref(2), '+', 'linew', 2, 'markersize', 10, 'color', doc.Cores.VERMELHO);

% 'Algorithm': 'active-set', 'interior-point', 'sqp', 'sqp-legacy', 'trust-region-reflective'
% options = optimoptions('fmincon', 'display', 'iter' , 'DiffMinChange', config.tstep*10, 'Algorithm', 'sqp');
options = optimoptions('fmincon', 'DiffMinChange', config.tstep*10, 'ConstraintTolerance', 1e-8, 'StepTolerance', 1e-8, 'Algorithm', 'active-set');
% options = optimoptions('fmincon', 'Algorithm', 'active-set');
x0  = [0.25, 0.25, config.x0];
lb  = [0.25, 0.25, config.x0 - 2.0];
ub  = [1.50, 1.50, config.x0 + 2.0];
A   = [];
b   = [];
Aeq = [];
beq = [];
% nonlincon = [];

[x, fval] = fmincon(@(x) doc.fun_custo_patino(config, x), x0, A, b, Aeq, beq, lb, ub, @(x) doc.nonlincon_patino(config, x), options);
% [x, fval] = fmincon(@(x) fun_custo_patino(config, x), x0, A, b, Aeq, beq, lb, ub, [], options);

% grafico da trajetoria final
config_    = config;

config_.Ts = doc.get_ts(x(1:2));
config_.x0 = x(3:4);
yf = doc.sim_1(config_);
plot(yf(:,1), yf(:,2), 'k', 'linew', 2);

% pontos de `xref` e `x0`

plot(config_.x0(1), config_.x0(2), 'o', 'linew', 2, 'color', doc.Cores.AZUL);

grid on;

%
% --------------------------------------
% RESULTADOS
% --------------------------------------

% otimizacao
disp('-----------------------------------')
fprintf('RESULTADOS:\n');
disp(['x    : [', num2str(x, '%.7f, ') ']']);
disp(['dT   : [', num2str(x(1:2), '%.7f, ') ']']);
disp(['Ts   : [', num2str(doc.get_ts(x), '%.7f, ') ']']);
disp(['fval : ', num2str(fval)]);

% pontos de cruzamento com as linhas de `xref`
% [Cx, Cy] = cruzamentos(yf, config.xref);
xmean = mean(yf);

diffx = config.xref(1) - xmean(1);
diffy = config.xref(2) - xmean(2);

fprintf('diferença centro cruzamento e `xref` : [%.6f, %.6f]\n', diffx, diffy);
disp(['fval : ', num2str(fval)]);

%%
% --------------------------------------
% SIMULACAO COMPLETA
% -------------------------------------- 
nsim = 50;

c = config_;
c.x0 = c.x0 + [0., 0.];
disp(c.x0);
[y,t,u] = doc.sim_n(c, nsim);

figure(2);
clf();
hold on;

plot(y(:,1), y(:,2));

plot(config.xref(1), config.xref(2), '+', 'linew', 2, 'markersize', 10, 'color', doc.Cores.VERMELHO);

% ultimo ciclo
c    = config_;
c.x0 = y(end,:);
yend = doc.sim_1(c);

% ymean = mean(yend);
% plot(ymean(1), ymean(2), 'o', 'linew', 2, 'color', doc.Cores.VERMELHO);

plot(yend(:,1), yend(:,2), 'k', 'linew', 2);
axis equal;
fprintf('xend ultimo ciclo: %.6f, %.6f\n', config_.x0(1), config_.x0(2));
grid on;