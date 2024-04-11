function Ts_out  = quantizacao(config, Ts)
    Ts_out = Ts;
    if isfield(config, 'quant')
        quant = config.quant;
    else 
        quant = -1;
    end
    
    if quant < 0
        return;
    end
    
    for i = 1:numel(Ts)
        tsi = Ts_out(i);
        resto = mod(tsi, quant);
        Ts_out(i) = tsi - resto;
    end
end