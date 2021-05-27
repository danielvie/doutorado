% MODELO DUPLO INTEGRADOR
Ac  = [0, 1;0, 0];
Bc  = [0; 1];

% PARAMETROS SIMULACAO

% passo do integrador da simulacao
dt_sim = 0.001;
t_fim  = 6*5;

% vetor de tempos
t    = [0, 2, 3, 5, 6]';
tr   = [2, 3, 5, 6]';
dtr  = diff(t);
T    = sum(dtr);

% vetor de comando u
ur   = [1, 0, -1, 0]';

% MATRIZES DO CONTROLADOR
N = numel(tr);
p = N - 1;

% [pag. 7 artigo]
Q  = eye(2);
R  = eye(p);
Np = 1;

% [pag. 7 artigo]
t_on  = 1.625;
t_off = 0.625;

c  = [
    -dtr(1) + t_on;
    -dtr(2) + t_off;
    -dtr(3) + t_on;
    -dtr(4) + t_off;
];

[Phi, Gamma] = construcao_modelo_instantes(Ac,Bc,tr,ur);

[H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = ...
    matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);


% SIMULACAO

% condicao inicial
x0   = [-0.5; -1];
x0_2 = [-0.5; -0.5];
x0_3 = [-5.1; 0.4];

x_target = x0;
y1 = run_simulink(x0);

y2 = run_simulink(x0_3);

figure(1)
clf;
plot_x(y1, 'linew', 2); 
hold on;
plot_x(y2, 'linew', 2, 'linestyle', '-.'); 
hold off;

figure(2);
clf;
plot_u(y1, 'linew', 2); 
hold on;
plot_u(y2, 'linew', 2, 'linestyle', '-.'); 
hold off;

mostra_dwell();

function yout = run_simulink(x0)
    % gravando valor de condicao inicial no workspace
    assignin('base', 'x0', x0);

    yout = sim('mod_integrador');
end

function value = get(yout, n)
    value = yout.logsout.get(n).Values;
end

function plot_x(yout, varargin)
    x  = get(yout, 'x');
    
    hold on;
    plot(x.data(:,1), x.data(:,2), varargin{:});
    hold off;
    grid on;    
end

function plot_u(yout, varargin)
    u  = get(yout, 'u');
    
    hold on;
    plot(u.time, u.data, varargin{:});
    hold off;
    grid on;    
end