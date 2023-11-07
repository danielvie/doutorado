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

    Omega = config.modes + 1;

    % Phi = expm(Ac*T);
    tam = N-1;
    Phi = eye(size(Ac{Omega(1)}));
    Ts  = [0; tr];
    Fr  = cell(tam, 1);
    
    dd = [];
    for i = 1:tam
        tti   = Ts(i+1);
        ti    = Ts(i);
        
        dti   = tti - ti;
        
        dd    = [dd,dti];
        
        Fr{i} = expm(Ac{Omega(i)}*dti);
        Phi   = Phi*Fr{i};
    end
    
    % FIXME: check de sanidade da equacao e indices
    Xr = xr;
    I  = eye(size(Fr{i}));

    p = N-1; % numero de variaveis manipuladas
    for i = 1:p-1

        % FF_1 = F_{n} * F_{n-1}... F{2}
        % FF_2 = F_{n} * F_{n-1}... F{3}
        % ...
        % FF_2 = F_{n}
        
        FF = I;
        for j = p:-1:(i+1)
            FF = FF*Fr{j};
        end

        Gamma(:,i) = FF*((Ac{Omega(i)}-Ac{Omega(i+1)})*Xr(i,:)' + Bc{Omega(i)} - Bc{Omega(i+1)});
    end

    Gamma(:,p) = (Ac{Omega(p)}*Xr(p,:)' + Bc{Omega(p)});
    
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
            Omega = config.modes + 1;
            xbar0 = xr(1,:)';
            Dt = diff(config.Ts);

            [Phi, Gamma] = linModel(A,b,Omega,xbar0,Dt);
        end
    end
end