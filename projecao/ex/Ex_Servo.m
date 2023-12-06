clear, clc, close all

A = [1 0.1;0 1];
B = [5e-3;0.1];

Q = diag([50,1]);
R = 1;
[K,P] = dlqr(A,B,Q,R);

C = [1 0];
aux = inv([A - eye(2) B;C 0])*[0;0;1];

Nx = aux(1:2);
Nu = aux(3);

rbar = pi;
xbar = Nx*rbar;
ubar = Nu*rbar;

Af = A-B*K;
Sx = [1 0;-1 0];
bx = [7*pi/6;pi/6];
Su = [1;-1];
bu = [5;2];

Gamma = [eye(2);-K];
Spsi = blkdiag(Sx,Su);
bpsi = [bx;bu];
max_iter = 10;
tol = 0;

[Sf,bf_til] = determina_oinf(Af,Gamma,Spsi,bpsi-[Sx*xbar;Su*ubar],max_iter,tol);
bf = bf_til + Sf*xbar;

x0 = [0;0];
N = 12;
un = dlqrcon(A,B,Q,R,P,N,Sx,bx,Su,bu,Sf,bf,x0,xbar,ubar);

% return

D = regiao_factibilidade(A,B,N,Sx,bx,Su,bu,Sf,bf);
plot(D,'Color','g'), hold on

return

% Oinf = Polyhedron('H',[Sf bf]);
% plot(Oinf)
% box on
% xlabel('x_1 (rad)','FontSize',12)
% ylabel('x_2 rad/s)','FontSize',12)
% set(gca,'FontSize',12,'YTick',[-4:1:4],'GridLineStyle','--')
% axis([-1 4 -4.5 4.5])
% hold on

% legend('Região de factibilidade D','Conjunto alvo X_f')
% export_fig -transparent -painters RegiaoFactibilidade_N12.pdf
% return

x{1} = [0;0];
for k = 1:N
    u(k) = un(k);
    x{k+1} = A*x{k} + B*u(k);
end
for k = N+1:N+30
    u(k) = ubar - K*(x{k} - xbar);
    x{k+1} = A*x{k} + B*u(k);
end

X = [x{1,:}];
h = plot(X(1,:),X(2,:),'b-o');
set(h,'LineWidth',2,'MarkerSize',7,'MarkerFaceColor','w')
h = plot(X(1,N+1),X(2,N+1),'ko')
set(h,'LineWidth',2,'MarkerSize',7,'MarkerFaceColor','g')
axis([-1 4 -2.5 3.5])
% set(gca,'FontSize',12,'YTick',[-2:1:4],'GridLineStyle','--')
% export_fig -transparent -painters ExOtimiza_x_N21.pdf

k = 0:N+30;
figure
h = line([0 40],[-2 -2]); box on; hold on
set(h,'LineWidth',2,'LineStyle','--','Color','r')
legend('Limitantes','Location','East')
h = line([0 40],[0 0]);
set(h,'Color','k','LineWidth',2)
h = stairs(k,[u u(end)])
set(h,'LineWidth',2)
grid
set(gca,'FontSize',12,'GridLineStyle','--')
xlabel('k','FontSize',12)
% ylim([-1 0.5])

hp = plot(N, u(N+1),'ko');
set(hp,'LineWidth',2,'MarkerSize',7,'MarkerFaceColor','g')

title('Torque u(k) / Nm','FontSize',12)
h = line([0 40],[5 5]);
set(h,'LineWidth',2,'LineStyle','--','Color','r')
ylim([-3 6])
xlim([0 40])
% export_fig -transparent -painters ExOtimiza_u_N21.pdf