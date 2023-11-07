% % FIXME: mudar nomes de `Ac` para `A`
% % FIXME: mudar nomes de `Bc` para `b`
% % FIXME: mudar indices de modos para inicio em `1`

% bla = load("bla");
% config = bla.config;

% tr  = config.Ts(2:end);
% ur  = [1, 0];
% dtr = diff(config.Ts);
% xr  = engine.get_xr(config);

% [Phi, Gamma] = mpc.construcao_modelo_instantes(config.Ac, config.Bc, tr, xr, config);



% % A, b : Cell arrays com as matrizes A e os vetores b correspondentes aos
% %        modos de chaveamento
% % Omega : Sequência de modos de chaveamento empregada
% % xbar0 : Estado inicial do ciclo
% % Dt : Intervalos de tempo entre os instantes de chaveamento

% A = config.Ac;
% b = config.Bc;
% Omega = config.modes + 1;
% xbar0 = xr(1,:)';
% Dt = diff(config.Ts);

% [Phi_,Gamma_] = linModel(A,b,Omega,xbar0,Dt);

vc1_off = y_off(:,1);
vc2_off = y_off(:,2);
i_l_off = y_off(:,3);

f4 = figure(4);
plot3(vc1, vc2, i_l);
hold on;
plot3(vc1_off, vc2_off, i_l_off);
hold off;

grid on;
xlabel('V_{c1} [V]');
ylabel('V_{c2} [V]');
zlabel('i_L [A]');
set(gca,'fontsize', 15);


f10 = figure(10);
stairs(t_off, m_off + 1, 'linew', 2);
hold on;
stairs(t, m1, 'linew', 2, 'linestyle', '--');
hold off;
xlim([0, 1.46e-3]);
grid on;
xlabel('time (s)');
ylabel('mode');
set(gca,'fontsize', 15);
legend('modes target trajectory', 'modes simulation');