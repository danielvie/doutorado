function [Phi, Gamma] = construcao_modelo_instantes(Ac, Bc, tr, xr, config)

    % Phi   = F_{N} F_{N-1} ... F_1

    % Gamma = [ 
    %          F_{N} F_{N-1} ... F_2 [(A_1 - A_2) x_bar(t_1) + B_1 - B_2
    %          F_{N} F_{N-1} ... F_3 [(A_2 - A_3) x_bar(t_2) + B_2 - B_3
    %                                     \...
    %          F_{N} [(A_{N-1} - A_{N}) x_bar(t_{N-1}) + B_{N-1} - B_{N}
    %          A_N x_bar(t_N) + B_{N}
    %         ]

    tr  = reshape(tr, [numel(tr), 1]);
    
    % T   = tr(N);
    % Dur = diff(ur); % Dur = [Dur1, Dur2, ..., DurN-1 ]

    Omega = config.Omega;

    N   = length(Omega); % calcular apenas uma vez N

    % Phi = expm(Ac*T);
    tam = N;
    Phi = eye(size(Ac{Omega(1)}));
    Ts  = [0; tr];
    Fr  = cell(tam, 1);
    
    % dd = zeros(numel(Ts), tam);
    % dd = [];
    for i = 1:tam
        tti   = Ts(i+1);
        ti    = Ts(i);
        
        dti   = tti - ti;
        
        % dd    = [dd,dti];
        % dd(i,:) = dti;
        
        Fr{i} = expm(Ac{Omega(i)}*dti);
        Phi   = Phi*Fr{i};
    end
    
    % FIXME: check de sanidade da equacao e indices
    Xr = xr;
    I  = eye(size(Fr{i}));

    p = N-1; % numero de variaveis manipuladas
    for i = 1:p

        % FF_1     = F_{n} * F_{n-1}... F{2}
        % FF_2     = F_{n} * F_{n-1}... F{3}
        % ...
        % FF_(N-1) = F_{n} * F_{n-1}
        % FF_N     = F_{n}

        FF = I;
        i0 = i + 1;
        for j = i0:N
            FF = FF*Fr{j};
        end
        
        i2 = i + 1;
        A1 = Ac{Omega(i)};
        A2 = Ac{Omega(i2)};
        b1 = Bc{Omega(i)};
        b2 = Bc{Omega(i2)};

        Gamma(:,i) = FF*((A1 - A2)*Xr(i,:)' + b1 - b2);
    end

    % Gamma(:,N) = (A2*Xr(p,:)' + b2);
    
    if ~isempty(config.kawa) 
        if (config.kawa == 1)
            disp('USANDO MODELO EXTENDIDO');
            disp('USANDO MODELO EXTENDIDO');
            disp('USANDO MODELO EXTENDIDO');
            disp('USANDO MODELO EXTENDIDO');
            disp('USANDO MODELO EXTENDIDO');
            disp('USANDO MODELO EXTENDIDO');
            disp('USANDO MODELO EXTENDIDO');
            disp('USANDO MODELO EXTENDIDO');
            A = config.Ac;
            b = config.Bc;
            Omega = config.Omega + 1;
            xbar0 = xr(1,:)';
            Dt = diff(config.Ts);

            [Phi, Gamma] = linModel(A,b,Omega,xbar0,Dt);
        end
    end
    
    % estado aumentado X = [x(t); 1]
    % estado aumentado A_tilde = [A_sigma(t), b_sigma(t); 
    %                                      0,          0]

    % Phi2 = phi(n)*phi(n-1)*...*phi(1)
    
    %{
        % Gamma2 = [
                phi(N) * phi(N-1) * ... * phi(2) * F_(N-1) * phi(1) * x(t0);
                phi(N) * phi(N-1) * ... * phi(3) * F_(N-1) * phi(2) * phi(1) * x(t0);
                ...
                phi(N) * F_(N-1) * phi(N-1) * phi(N-2) * ... phi(1) * x(t0);
                F_(N) * phi(N) * phi(N-1) * ... phi(1) * x(t0);
            ]
    %}
    
    % F(n) = A_tilde_sigma(t)
    % phi(n) = expm(F(n)*Dt(N))
    
    [a_m, a_n] = size(Ac{Omega(1)});
    [b_m, b_n] = size(Bc{Omega(1)});
    
    F = {};
    phi = {};
    for i = 1:N
        Ai = Ac{Omega(i)};
        bi = Bc{Omega(i)};

        % computando matriz de estados aumentada
        F{i} = [Ai, bi; zeros(1, a_n), zeros(1, b_n)];
        
        % calculando phi{n}
        dti    = Ts(i+1) - Ts(i);
        phi{i} = expm(F{i}*dti);
    end
    
    % calculando Phi2
    Phi2 = eye(size(F{1}));
    for i = 1:N
        Phi2 = Phi2*phi{i};
    end

    % calculando Gamma2
    Gamma2 = [];
    x0 = Utils.get_x0(config);
    xt0 = [x0; 1];
    I = eye(size(F{1}));

    for i = 1:N
        FF = I;
        for j = 1:N
            if (i == j)
                FF = FF*F{j};
            end
            FF = FF*phi{j};
        end
        FF = FF*xt0;

        Gamma2 = [Gamma2, FF];
    end

    % A = Ac;
    % b = Bc;
    % % Omega = config.Omega + 1;
    % xbar0 = xr(1,:)';
    % Dt = diff(config.Ts);

    % [Phi3, Gamma3] = linModel(A,b,Omega,xbar0,Dt);
    
    % bla = 1;
    
end