function [Phi, Gamma, Phi_, Gamma_] = construcao_modelo_instantes_aumentado(Ac,Bc,tr,xr,config)

    % estado aumentado X = [x(t); 1]
    % estado aumentado A_tilde = [A_sigma(t), b_sigma(t); 
    %                                      0,          0]

    %{
        % Phi = phi(n)*phi(n-1)*...*phi(1)
    
        % Gamma = [
            F(N) * phi(N) * phi(N-1) * ... * phi(1) * x(t0);
            phi(N) * F(N-1) * phi(N-1) * ... * phi(1) * x(t0);
            ...
            phi(N) * phi(N-1) * F(N-2) * phi(N-2) * ... phi(1) * x(t0);
            phi(N) * phi(N-1) * ... F(1) * phi(1) * x(t0);
        ]
    %}
    
    % F(n) = A_tilde_sigma(t)
    % phi(n) = expm(F(n)*Dt(N))
    
    % calculando F e phi
    tr  = reshape(tr, [numel(tr), 1]);
    N   = length(tr); % calcular apenas uma vez N
    Omega = config.Omega;
    Ts  = [0; tr];

    [a_m, a_n] = size(Ac{Omega(1)});
    [b_m, b_n] = size(Bc{Omega(1)});

    F = {};
    phi = {};
    for i = 1:N
        Ai = Ac{Omega(i)};
        bi = Bc{Omega(i)};

        % computando matriz de estados aumentada
        F{i} = [Ai, bi; zeros(1, a_n), 0];
        
        % calculando phi{n}
        dti    = Ts(i+1) - Ts(i);
        phi{i} = expm(F{i}*dti);
    end
    
    % calculando Phi
    Phi = eye(size(F{1}));
    for i = 1:N
        Phi = Phi*phi{i};
    end

    % calculando Gamma2
    Gamma = [];
    % x0 = engine.get_x0(config);
    x0 = config.x0;
    xt0 = [x0; 1];
    % I = eye(size(F{1}));

    for i = 1:N
        FF = xt0;
        for j = 1:N
            if (i == j)
                FF = F{j}*FF;
            end
            FF = phi{j}*FF;
        end

        Gamma = [Gamma, FF];
    end

    % gerando matrizes estado aumentado
    Phi_ = Phi(1:end-1,1:end-1);

    % por que te tem essa parte aqui?
    col = [1;-1;zeros(N-2,1)];
    row = [1 zeros(1,N-2)];
    Gamma_ = Gamma(1:end-1,:) * toeplitz(col,row);
end