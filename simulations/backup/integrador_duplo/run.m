% SIMULACAO
t_fim  = 6*5;

% condicao inicial
x0   = [-0.5; -1];
x0_2 = [-0.5; -0.5];
x0_3 = [-5.1; 0.4];

x_target = x0;
% y1 = run_matlab(x0);
% y2 = run_matlab(x0_3);

Cc = eye(2);
Dc = [0;0];

% simulacao
nsim = 4;

y1 = run_sim(x0, x_target, nsim);
y2 = run_sim(x0_3, x_target, nsim);

% grafico de trajetoria
figure(3)   
plot(y1(:,1), y1(:,2), 'linew', 2); hold on;
plot(y2(:,1), y2(:,2), 'linew', 2, 'linestyle', '--'); hold off;
grid on;

function y = run_sim(x0, x_target, nsim)
    H      = evalin('base', 'H');
    Hf     = evalin('base', 'Hf');
    Phi1Np = evalin('base', 'Phi1Np');
    Qbar   = evalin('base', 'Qbar');
    Rbar   = evalin('base', 'Rbar');
    Lbar   = evalin('base', 'Lbar');
    cbar   = evalin('base', 'cbar');
    Pf     = evalin('base', 'Pf');
    Sf     = evalin('base', 'Sf');
    bf     = evalin('base', 'bf');
    PhiNp  = evalin('base', 'PhiNp');
    p      = evalin('base', 'p');

    y   = [];
    for i = 1:nsim
        % calculo `ek`
        ek = x0 - x_target;

        % calculo comando `dtk`
        dtk = mpc_dualmode_switching(ek,H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,p);

        % simulando dinamica
        y_ = run_cicle(x0, dtk);
        x0 = y_(end,:)';

        y  = [y;y_];
    end
end

function y = run_cicle(x0, dtk)
    if nargin == 1
        dtk = [0;0;0];
    end
    
    Ac = evalin('base', 'Ac');
    Bc = evalin('base', 'Bc');
    Cc = evalin('base', 'Cc');
    Dc = evalin('base', 'Dc');
    tr = evalin('base', 'tr');
    ur = evalin('base', 'ur');
    
    % ajuste dtk
    tr_ = tr;
    tr_(1:3) = tr_(1:3) + dtk;
    
    % ciclo 1
    t1 = 0:0.001:tr_(1);
    t1 = t1(1:end-1);
    u1 = ones(size(t1))*ur(1);
    y1 = lsim(Ac,Bc,Cc,Dc,u1,t1 - t1(1),x0);

    % ciclo 2
    t2 = tr_(1):0.001:tr_(2);
    t2 = t2(1:end-1);
    u2 = ones(size(t2))*ur(2);
    y2 = lsim(Ac,Bc,Cc,Dc,u2,t2 - t2(1),y1(end,:));

    % ciclo 3
    t3 = tr_(2):0.001:tr_(3);
    t3 = t3(1:end-1);
    u3 = ones(size(t3))*ur(3);
    y3 = lsim(Ac,Bc,Cc,Dc,u3,t3 - t3(1),y2(end,:));

    % ciclo 4
    t4 = tr_(3):0.001:tr_(4);
    t4 = t4(1:end-1);
    u4 = ones(size(t4))*ur(4);
    y4 = lsim(Ac,Bc,Cc,Dc,u4,t4 - t4(1),y3(end,:));

    % montando resposta
    y  = [y1;y2;y3;y4];
end
