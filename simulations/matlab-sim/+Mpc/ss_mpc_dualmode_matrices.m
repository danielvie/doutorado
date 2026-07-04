function [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,K,L] = ss_mpc_dualmode_matrices(Phi, Gamma, Q, R, Np, c)
    % Restricao (at each cycle): L*dt <= c
    % f = Phi * Xi(k)
 
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
    
    % Determination of terminal gain K
    K = dlqr(Phi,Gamma,Q,R);
    % disp('ganho terminal K:')
    % disp(K)
    Phib = Phi - Gamma*K;
    
    % Determination of terminal cost matrix Pf
    % Eq. Lyapunov:
    % Phib'*Pf*Phib - Pf + Phib'*Q*Phib + K'*R*K = 0
    Pf = dlyap(Phib',Phib'*Q*Phib + K'*R*K);
    
    % Simple conservative approximation of the terminal invariant set
    % We use the constraint L*K*x <= c directly
    % Sf = L*K;  % Terminal state constraints
    % bf = c;    % Terminal constraint bounds
    
    % Note: This is a simplified approach. For more accurate results,
    % you might want to iterate a few times to get a better approximation
    % of the maximal invariant set

    % Determining the invariant and admissible terminal set
    % Requires MPT Toolbox
    sys = LTISystem('A',Phib);
    Hmpt = [L*K  -c];
    X = Polyhedron('H',Hmpt);
    
    warning off;
    S = sys.invariantSet('X',X);
    warning on;
    
    aux = S.H;
    Sf = aux(:,1:(end-1));
    bf = aux(:,end);
end