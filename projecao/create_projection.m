% aula 8

% a projecao pode ser realizada empregando a funcao 'projection' do MPT Toolbox
% {aula8, slide 33}

% sendo Sf, bf obtidos na caracterizacao de O_inf com os valores de equilibrio xbar, ubar considerados
% {aula8, slide 10}

function var_out = create_projection(config)


    %{
        input:
            config:
                A, B, C: dynamic matrices
                Q, R, Pf: weight parameters
                Sx, bx, Su, bu: restrictions
                N: ?? [default: 10]
    %}


    % LENDO PARAMETROS
    A = config.A;
    B = config.B;

    Q = config.Q;
    R = config.R;

    Sx = config.Sx;
    bx = config.bx;
    Su = config.Su;
    bu = config.bu;

    xbar = config.xbar;
    ubar = config.ubar;

    N = config.N;

    % CALCULO DA REGIAO DE FACTIBILIDADE
    [K,~] = dlqr(A,B,Q,R); % Projeto DLQR com pesos unitários
    Af = A-B*K;
    Gamma = [eye(2);-K];
    Spsi = blkdiag(Sx,Su); bpsi = [bx;bu];
    max_iter = 100;
    tol = 0;

    [Sf,bf_til] = determina_oinf(Af,Gamma,Spsi,bpsi-[Sx*xbar;Su*ubar],max_iter,tol);
    bf = bf_til + Sf*xbar;

    Sun = Su;
    An = A;
    for i = 2:N
        Sun = blkdiag(Sun,Su);
        An = [An;A^i];
    end
    bun = repmat(bu,N,1);

    n = size(B,1);
    p = size(B,2);
    % Bn = zeros(n*N,p*N);

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

    Sw = [Sxn*Bn Sxn*An;
        Sun zeros(size(Sun,1),n);
        zeros(size(Sx,1),p*N) Sx];
    bw = [bxn; bun; bx];
    
    Pw = Polyhedron('H',[Sw bw]);
    D = projection(Pw,p*N+1:p*N+n);

    % getting all variables as reponse parameter
    varnames = who;
    var_out = struct();
    for i = 1:numel(varnames)
        vi = varnames{i};
        
        var_out.(vi) = eval(vi);
    end
end