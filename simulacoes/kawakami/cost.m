function [J,xrec] = cost(dt,A,b,Omega,xref,Q,Nsim)

s = length(Omega); % Number of switchings
n = size(A{1},1); % Number of states

% Step 1: Obtains Fa
for j = 1:s
    Aa{j} = [A{Omega(j)} b{Omega(j)};zeros(1,n) 0];
    Fa{j} = expm(Aa{j}*dt(j));
end

% Step 2: Calculates x0
prodFa = Fa{1};
for j = 2:s
    prodFa = Fa{j}*prodFa;
end
aux = eye(n+1) - prodFa;
Z = aux(1:n,1:n);
w = -aux(1:n,n+1);

if rank(Z) == n
    x0 = inv(Z)*w;
else
    % min(x0 - xref)'Q(x0 - xref) s.a. Zx0 = w
    Hqp = 2*Q;
    fqp = 2*Q*xref;
    x0 = quadprog(Hqp,fqp,[],[],Z,w);
end

% Step 3: Simulation and cost evaluation
J = 0;
xswitcha = [x0;1];
xrec = []; % Record of the simulation result
for j = 1:s
    dtminor = dt(j)/Nsim; % Minor time step
    Fasim = expm(Aa{j}*dtminor);
    xka = xswitcha;
    xrec = [xrec xka(1:n)];
    for k = 1:(Nsim-1) % The value at k = Nsim will be calculated with the major time step dt(j)
        xk = xka(1:n);
        J = J + (xk - xref)'*Q*(xk - xref)*dtminor;
        xkap1 = Fasim*xka;
        xrec = [xrec xkap1(1:n)];
        xka = xkap1;
    end
    xswitcha = Fa{j}*xswitcha; % Jumps to the beginning of the next cycle
end
