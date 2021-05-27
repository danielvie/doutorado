function [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c)

% Restrição (at each cycle): L*dt <= c

n = size(Phi,1);
p = size(Gamma,2);
N = p + 1;

H = zeros(n*Np,p*Np);
for i = 1:Np
   for j = 1:i
       H(1+(i-1)*n:i*n , 1+(j-1)*p:j*p) = (Phi^(i-j))*Gamma;
   end
end

Hf = H(end-n+1:end,:);

Phi1Np = Phi;
for i = 2:Np
    Phi1Np = [Phi1Np;Phi^i];
end

col = [1;-1;zeros(N-2,1)];
row = [1 zeros(1,N-2)];
L = toeplitz(col,row);

Qbar = Q; Rbar = R; Lbar = L;
for i = 2:Np
    Qbar = blkdiag(Qbar,Q);
    Rbar = blkdiag(Rbar,R);
    Lbar = blkdiag(Lbar,L);
end

cbar = repmat(c,Np,1);

PhiNp = Phi^Np;

% Determinação do ganho terminal K
K = dlqr(Phi,Gamma,Q,R);
Phib = Phi - Gamma*K;

% Determinação da matriz de custo terminal Pf
% Eq. Laypunov:
% Phib'*Pf*Phib - Pf + Phib'*Q*Phib + K'*R*K = 0
%
%     X = dlyap(A,Q) solves the discrete Lyapunov matrix equation:
%  
%         A*X*A' - X + Q = 0

Pf = dlyap(Phib',Phib'*Q*Phib + K'*R*K);

% Determinação do conjunto terminal invariante e admissível
% Requer o MPT Toolbox
sys = LTISystem('A',Phib);
Hmpt = [L*K  -c];
X = Polyhedron('H',Hmpt);
S = sys.invariantSet('X',X);
aux = S.H;
Sf = aux(:,1:(end-1));
bf = aux(:,end);