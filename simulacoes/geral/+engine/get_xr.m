function Xr = get_xr(config)

    A  = config.Ac;
    B  = config.Bc;
    Ts = config.Ts;

    M  = config.modes;
    
    % x1 = F1*X0 + G1;
    % x2 = F2*X1 + G2;
    % ...

    Xr = reshape(config.x0, [1, numel(config.x0)]);
    for i = 1:numel(M)
        mi  = M(i) + 1;
        Ai  = A{mi};
        Bi  = B{mi};
        dti = Ts(i+1) - Ts(i);

        [Fi, Gi] = c2dm(Ai,Bi,[],[],dti,'zoh');
        xi       = Fi*Xr(i,:)' + Gi;

        Xr = [Xr;xi'];
    end

end