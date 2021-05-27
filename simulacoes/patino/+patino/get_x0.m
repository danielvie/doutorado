function x0 = get_x0(config)
    % montando matrizes F e G
    Ts = config.Ts;
    n  = numel(config.modes);
    ur = config.ur;
    F  = cell(n,1);
    G  = cell(n,1);
    for i = 1:n
        mi = config.modes(i) + 1;
        Ai = config.Ac{mi};
        Bi = config.Bc{mi};

        dt = Ts(i+1) - Ts(i);
        [Fi, Gi] = c2dm(Ai, Bi, [], [], dt, 'zoh');

        F{i} = Fi;
        G{i} = Gi;
    end
    
    % calculando `c`
    c = G{n}*ur(n);
    for i = 2:n
        ci = F{n};
        for j = n-1:-1:i
            ci = ci*F{j};
        end        
        ci = ci*G{i-1}*ur(i-1);

        c  = c + ci;
    end
    
    % calculando FF
    FF = F{n};
    for i = n-1:-1:1
        FF = FF*F{i};
    end

    % calculando x0
    I  = eye(size(FF));
    x0 = (I - FF)\c;
end