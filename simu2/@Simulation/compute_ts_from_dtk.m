    function Ts = compute_ts_from_dtk(self, config, dtk)
    % Applies time adjustments based on control signal dtk
    % Returns the adjusted time vector
    
    % start with base time vector
    Ts = config.Ts;
    
    % apply quantization
    % Ts = self.quantizacao(Ts, Enums.QuantType.Sim);
    
    % adjust time vector based on control signal
    for j = 1:numel(dtk)
        Ts(j+1) = Ts(j+1) + dtk(j);
    end

    ts_ = config.Ts;
    ts_(2) = ts_(2) + dtk(1);
    ts_(3) = ts_(3) + dtk(2);
    ts_(4) = ts_(4) + dtk(3);
    ts_(5) = ts_(5) + dtk(4);
    ts_(6) = ts_(6) + dtk(5);
        
    bla = 1;
    


end
