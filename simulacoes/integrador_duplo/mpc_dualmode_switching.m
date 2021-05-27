function dtk = mpc_dualmode_switching(ek,H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,p)

Hqp = 2*(H'*Qbar*H + Rbar + Hf'*Pf*Hf);
Hqp = (Hqp + Hqp')/2; % Simetrização

fu = Phi1Np*ek;
fqp = 2*(H'*Qbar*fu + Hf'*Pf*PhiNp*ek);
Aqp = [-Lbar;
       Sf*Hf];
bqp = [-cbar;
       bf - Sf*PhiNp*ek];

options = optimoptions('quadprog', 'Algorithm', 'active-set');

x0  = zeros(size(fqp, 1), 1);
Dtk = quadprog(Hqp,fqp,Aqp,bqp,[],[],[],[],x0,options);

dtk =  Dtk(1:p);