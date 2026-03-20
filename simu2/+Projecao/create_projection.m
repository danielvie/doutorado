function var_out = create_projection(config)
    % create_projection - Compute the feasibility region of the system.
    % 
    % Note: This function uses the package +Projecao to calculate the feasibility
    %       region and employs the MPT Toolbox for projection operations.
    % 
    % Syntax: var_out = create_projection(config)
    %
    % Inputs:
    %   config - A structure containing the following fields:
    %       A, B       - System dynamic matrices.
    %       Q, R       - Weighting matrices for the DLQR controller.
    %       Sx, bx     - State constraints (Sx * x <= bx).
    %       Su, bu     - Input constraints (Su * u <= bu).
    %       xbar, ubar - Equilibrium state and input.
    %       N          - Prediction horizon.
    %
    % Outputs:
    %   var_out - A structure containing all computed variables

    % LENDO PARAMETROS
    A = config.A;
    B = config.B;

    Q = config.Q;
    R = config.R;

    Sx = config.Sx;
    bx = config.bx;
    Su = config.Su;
    bu = config.bu;

    % xbar = config.xbar;
    % ubar = config.ubar;

    N = config.N;

    % CALCULO DA REGIAO DE FACTIBILIDADE
    [K,~]    = dlqr(A,B,Q,R); % Projeto DLQR
    Af       = A-B*K;
    Gamma    = [eye(size(A,2));-K];
    Spsi     = blkdiag(Sx,Su); 
    bpsi     = [bx;bu];
    max_iter = 100;
    tol      = 0;

    [Sf,bf] = Projecao.determina_oinf(Af,Gamma,Spsi,bpsi,max_iter,tol);

    % Restoring the 1e5 scaling: MPT has fixed internal tolerances (e.g. 1e-6),
    % without this scaling, the small values in bf are grouped as zero, which
    % cuts off massive valid chunks of the polytope.
    Sf = Sf*1e5;
    bf = bf*1e5;
    
    Sun = Su;
    An  = A;
    for i = 2:N
        Sun = blkdiag(Sun,Su);
        An = [An;A^i];
    end
    bun = repmat(bu,N,1);

    n = size(B,1);
    p = size(B,2);

    Baux = mat2cell(zeros(n*N,p*N),n*ones(N,1),p*ones(1,N));
    for i = 1:N
        for j = 1:i
            Baux{i,j} = (A^(i-j))*B;
        end
    end
    Bn = cell2mat(Baux);

    if N > 1
        Sxn = Sx;
        for i = 2:N-1
            Sxn = blkdiag(Sxn,Sx);
        end
        Sxn = blkdiag(Sxn,Sf);
    else
        Sxn = Sf;
    end

    bxn = [repmat(bx,N-1,1);bf];

    Sw = [
            Sxn*Bn                  Sxn*An;
            Sun                     zeros(size(Sun,1),n);
            zeros(size(Sx,1),p*N)   Sx
        ];
    bw = [bxn; bun; bx];
    
    H_mat = [Sw bw];
    
    Pw = Polyhedron('H', H_mat);
    % Project onto state dimensions 
    % State variables are at the end of the decision vector in Sw [u1...uN x]
    D = Pw.projection(p*N+1: p*N+n);
    
    % Ensure irredundant representation (Guarantees the boundaries mathematically)
    D.minHRep();
    % Compute and minimize V-representation to fix rendering bugs with missing faces
    D.computeVRep();
    D.minVRep();


    % GETTING ALL VARIABLES AS RESPONSE PARAMETER
    var_out = Utils.getAllVars();
end