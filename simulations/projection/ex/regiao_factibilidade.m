function D = regiao_factibilidade(A,B,N,Sx,bx,Su,bu,Sf,bf)

Sun = Su;
An = A;
for i = 2:N
    Sun = blkdiag(Sun,Su);
    An = [An;A^i];
end
bun = repmat(bu,N,1);

n = size(B,1);
p = size(B,2);
Bn = zeros(n*N,p*N);

Baux = mat2cell(zeros(n*N,p*N),n*ones(N,1),p*ones(1,N));
for i = 1:N
    for j = 1:i
        Baux{i,j} = (A^(i-j))*B;
    end
end
Bn = cell2mat(Baux);

Sxn = Sx;
for i = 2:N-1
    Sxn = blkdiag(Sxn,Sx);
end
Sxn = blkdiag(Sxn,Sf);
bxn = [repmat(bx,N-1,1);bf];

Sw = [Sxn*Bn Sxn*An;
      Sun zeros(size(Sun,1),n);
      zeros(size(Sx,1),p*N) Sx];
bw = [bxn; bun; bx];
  
Pw = Polyhedron('H',[Sw bw]);

D = projection(Pw,p*N+1:p*N+n);