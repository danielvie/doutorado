function x0 = get_x0(config)

    %{
        usando equacao 2.10 da tese
            x(tn) = F(n-1)*F(n-2)*...*F(0)*x_0 + c == FF*x_0 + c
            x_0   = (I - FF)\c
            
        com 
            FF = F(n-1)*F(n-2)*...*F(0)
            c = F(n-1)F(n-2)...F1g0 + F(n-1)F(n-2)...F2g1 + ... + F(n-1)g(n-2) + g(n-1)

            [Fi, gi] = c2dm(Ai, bi, [], [], dt, 'zoh')
            ou
            usar o estado aumentado Xa = [X0;1] e resolver Xa[k+1] = Aa*Xa[k]
            com Aa = [ Ai, bi
                        0,  0]
    %}

    % inicializando variaveis de apoio
    n  = numel(config.Omega);
    F  = cell(n,1);
    g  = cell(n,1);
    
    [m_, n_] = size(config.A{1});
    I  = eye(m_, n_);

    for i = 1:n
        mi = config.Omega(i);
        Ai = config.A{mi};
        bi = config.b{mi};

        % calculando `Fi` e `gi` por estado aumentado
        %  Aa = [ Ai, bi
        %          0,  0]
        dt   = config.Ts(i+1) - config.Ts(i);
        Fa   = expm([Ai, bi;zeros(1, size(Ai, 2)), 0]*dt);
        F{i} = Fa(1:m_, 1:n_);
        g{i} = Fa(1:m_, n_+1:end);
    end
    
    % calculando `c`
    %       c = F(n-1)F(n-2)...F1g0 + F(n-1)F(n-2)...F2g1 + ... + F(n-1)g(n-2) + g(n-1)
    %
    c = g{n};
    for i = 2:n
        FFi = I;
        for j = n:-1:i
            FFi = FFi*F{j};
        end        

        c = c + FFi*g{i-1};
    end
    
    % calculando FF
    %       FF = F(n-1)F(n-2)...F1
    FF = I;
    for i = n:-1:1
        FF = FF*F{i};
    end

    % calculando x0
    x0 = (I - FF)\c;    
    
end