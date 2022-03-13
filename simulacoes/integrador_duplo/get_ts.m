function Ts = get_ts(dT)
    
    Ts = zeros(1, numel(dT) + 1);
    for i = 2:numel(Ts)
        Ts(i) = Ts(i-1) + dT(i-1);
    end
    
end