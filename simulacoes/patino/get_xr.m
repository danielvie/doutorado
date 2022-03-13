function Xr = get_xr(config)

    % montando matrizes F e G
    Ts = config.Ts;
    n  = numel(config.modes);
    ur = config.ur;
    F  = cell(n,1);
    G  = cell(n,1);

    Xr = [];
    Xr = [Xr;config.x0];
    for i = 1:n-1
        mi = config.modes(i) + 1;
        Ai = config.Ac{mi};
        Bi = config.Bc{mi};

        dt = Ts(i+1) - Ts(i);
        [Fi, Gi] = c2dm(Ai, Bi, [], [], dt, 'zoh');

        F{i} = Fi;
        G{i} = Gi;
        
        Xri = (F{i}*Xr(1,:)' + G{i})';
        Xr = [Xr;Xri];
%         bla = 1;
%         Xr
    end
    

end