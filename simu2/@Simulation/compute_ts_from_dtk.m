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
end
