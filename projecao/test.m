clear all

% aula 8

% modelo discretizado com T = 0.1s
A = [1, 0.1; 0, 1];
B = [5*1e-3;0.1];
C = [1, 0];

% ganho de realimentacao K usando DLQR
Q = [50, 0; 0, 1];
R = 1;
Pf = diag([1, 1]);

% restricoes
Sx = [1, 0; -1, 0];
bx = [4*pi/6; pi/6];
Su = [1;-1];
bu = [5; 2];

N = 10;


% a projecao pode ser realizada empregando a funcao 'projection' do MPT Toolbox
% {aula8, slide 33}


% sendo Sf, bf obtidos na caracterizacao de O_inf com os valores de equilibrio xbar, ubar considerados
% {aula8, slide 10}



% retirado do exemplo.m
[K,P] = dlqr(A,B,Q,R); % Projeto DLQR com pesos unitários
Af = A-B*K;
Gamma = [eye(2);-K];
Spsi = blkdiag(Sx,Su); bpsi = [bx;bu];
max_iter = 100;
tol = 0;
[Sf,bf] = determina_oinf(Af,Gamma,Spsi,bpsi,max_iter,tol);



Qn = Q; Sxn = Sx;
for i = 2:N-1
    Qn = blkdiag(Qn, Q);
    Sxn = blkdiag(Sxn, Sx);
end
Qn = blkdiag(Qn, Pf);
Sxn = blkdiag(Sxn, Sf);
bxn = [repmat(bx,N-1,1); bf];

An = A; Rn = R; Sun = Su;
for i = 2:N
   An = [An;A^i];
   Rn = blkdiag(Rn,R);
   Sun = blkdiag(Sun,Su);
end
bun = repmat(bu,N,1);



n = size(B, 1);
p = size(B, 2);
Baux = mat2cell(zeros(n*N, p*N), n*ones(N,1), p*ones(1,N));
for i = 1:N
    for j = 1:i
        Baux{i,j} = (A^(i-j))*B;
    end
end
Bn = cell2mat(Baux);


% projection
Sw = [Sxn*Bn Sxn*An;
      Sun zeros(size(Sun, 1), n);
      zeros(size(Sx,1), p*N) Sx];
      
bw = [bxn; bun; bx];

Pw = Polyhedron('H', [Sw bw]);

D = projection(Pw, p*N+1:p*N+n);