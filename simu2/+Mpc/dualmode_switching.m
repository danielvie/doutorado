function [dtk, fval, exitflag] = dualmode_switching(ek, H, Hf, Phi1Np, Qbar, Rbar, Lbar, cbar, Pf, Sf, bf, PhiNp, p)
    
    % dtk: optimization result
    % fval: objective function value at solution
    % exitflag: reason quadprog stopped
    %            1: function converged to the solution x
    %            0: number of iterations exceeded MaxIterations
    %           -2: problem is infeasible
    %           -3: problem is unbounded

    % para o quadprog, eh preciso
    % X = quadprog(H,f,A,b)
    % min 0.5*x'*H*x + f'*x   subject to:  A*x <= b 
    %  x     
    % 
    % ek = estados de erros
    % H = 
    % Hf = 
    % Phi1Np = 
    % Qbar = peso x
    % Rbar = peso u
    % Lbar, cbar = constraint `L * x <= c`
    % Pf = peso x_terminal
    % Sf, bf = constraing `S * x <= b`
    % PhiNp = 
    % p = numero de variaveis manipuladas


    H_qp = 2*(H'*Qbar*H + Rbar + Hf'*Pf*Hf);
    H_qp = (H_qp + H_qp')/2; % Simetrizacao

    fu   = Phi1Np*ek;
    f_qp = 2*(H'*Qbar*fu + Hf'*Pf*PhiNp*ek);

    A_qp = [-Lbar;
             Sf*Hf];
    b_qp = [-cbar;
             bf - Sf*PhiNp*ek];

    Aeq_qp = [];
    beq_qp = [];
    lb_qp  = [];
    ub_qp  = [];
%     lb_qp  = ones(9,1) * 2.2e-5;
%     ub_qp  = ones(9,1) * 0.0004;

    % quadprog(H,f,A,b,Aeq,beq,lb,ub,x0,options)
    % min 0.5 x^T H x + f^T; such that
    %    A.x <= b,
    %    Aeq.x == b,
    %    lb <= x <= ub,

    % options = optimoptions('quadprog', 'Algorithm', 'interior-point-convex');
    options = optimoptions('quadprog', 'Algorithm', 'active-set');
    
    x0  = zeros(size(f_qp, 1), 1);
    [Dtk, fval, exitflag] = quadprog(H_qp,f_qp,A_qp,b_qp,Aeq_qp,beq_qp,lb_qp,ub_qp,x0,options);

%     options = optimoptions('quadprog', 'Algorithm', 'interior-point-convex');
%     
%     x0  = zeros(size(f_qp, 1), 1);
%     Dtk = quadprog(H_qp,f_qp,A_qp,b_qp,Aeq_qp,beq_qp,lb_qp,ub_qp,x0,options);

    dtk =  Dtk(1:p);
end
