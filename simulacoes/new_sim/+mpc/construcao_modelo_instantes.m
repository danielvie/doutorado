function [Phi, Gamma] = construcao_modelo_instantes(Ac,Bc,tr,xr)

    % tr = [tr1, tr2, ..., trN]'
    % Assume-se tr0 = 0 e, portanto, T = trN
    % ur = [ur(tr0), ur(tr1), ..., ur(trN-1)]
    
    tr  = reshape(tr, [numel(tr), 1]);
    
    N   = length(tr); % calcular apenas uma vez N

    % T   = tr(N);
    % Dur = diff(ur); % Dur = [Dur1, Dur2, ..., DurN-1 ]
    
    % Phi = expm(Ac*T);
    tam = N-1;
    Phi = eye(size(Ac{1}));
    Ts  = [0; tr];
    Fr  = cell(tam, 1);
    for i = 1:tam
        tti   = Ts(i+1);
        ti    = Ts(i);
        
        dti   = tti - ti;
        
        Fr{i} = expm(Ac{i}*dti);
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

        
        fim = p;
        ini = i + 1;

        FF = I;
        for j = fim:-1:ini
            FF = FF*Fr{j};
        end
        
        % Gamma(:,i) = FF*(Fr{i}*Ac{i}*Xr(i,:)' + Ac{i}*Gri + Bc{i} + Bc{i+1});
        Gamma(:,i) = FF*((Ac{i}-Ac{i+1})*Xr(i,:)' + Bc{i} - Bc{i+1});
    end

    Gamma(:,p) = (Ac{p}*Xr(p,:)' + Bc{p});

    bla = 1;
end