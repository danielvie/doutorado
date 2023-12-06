function [Phi, Gamma] = construcao_modelo_instantes(Ac,Bc,tr,xr,config)

    % Phi   = F_{N} F_{N-1} ... F_1

    % Gamma = [ 
    %          F_{N} F_{N-1} ... F_2 [(A_1 - A_2) x_bar(t_1) + B_1 - B_2
    %          F_{N} F_{N-1} ... F_3 [(A_2 - A_3) x_bar(t_2) + B_2 - B_3
    %                                     ...
    %          F_{N} [(A_{N-1} - A_{N}) x_bar(t_{N-1}) + B_{N-1} - B_{N}
    %          A_N x_bar(t_N) + B_{N}
    %         ]

    tr  = reshape(tr, [numel(tr), 1]);
    
    N   = length(tr); % calcular apenas uma vez N

    % T   = tr(N);
    % Dur = diff(ur); % Dur = [Dur1, Dur2, ..., DurN-1 ]

    Omega = config.Omega;

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
    
    if (isfield(config, 'kawa')) 
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
end