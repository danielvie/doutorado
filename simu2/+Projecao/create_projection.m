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
    n = size(A, 1);
    p = size(B, 2);

    Spsi = blkdiag(Sx, Su);
    bpsi = [bx; bu];
    max_iter = 100;
    tol      = 0;

    if isfield(config, 'Sf') && ~isempty(config.Sf)
        Sf = config.Sf;
        bf = config.bf;
        Si = {}; bi = {}; % Not needed for projection building
    else
        [Sf,bf,Si,bi] = Projecao.determina_oinf(Af,Gamma,Spsi,bpsi,max_iter,tol);
        
        % Consistent fallback: check if the terminal set O_inf is valid BEFORE building Sw.
        % This ensures all N horizons use the SAME Sf/bf, preserving the nesting property.
        % A valid O_inf must satisfy Sf*0 <= bf, i.e. bf >= 0 (origin must be feasible).
        % If any bf < -tol, determina_oinf ran one extra iteration and accumulated a
        % contradictory constraint row. Use the second-to-last iteration set instead.
        if isempty(Sf) || isempty(bf) || any(bf < -1e-9)
            if ~isempty(Si) && numel(Si) >= 2
                Sf = Si{end-1};
                bf = bi{end-1};
                disp('Warning: terminal set O_inf is infeasible. Using second-to-last MAS iteration.');
            elseif ~isempty(Si)
                Sf = Si{end};
                bf = bi{end};
                disp('Warning: terminal set O_inf is infeasible. Using last MAS iteration.');
            else
                error('create_projection: could not characterize MAS (Sf/bf invalid).');
            end
        end
    end
    
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
    
    % Normalize H-matrix for numerical stability (Mandatory since 1e5 scaling is removed)
    for k = 1:size(H_mat,1)
        nrm = norm(H_mat(k,1:end-1));
        if nrm > 1e-12
            H_mat(k,:) = H_mat(k,:) / nrm;
        end
    end
    
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