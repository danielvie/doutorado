function Ts_out  = quantizacao(self, Ts, type)
    
    config = self.m_config;

    Ts_out = Ts;

    % selecionar tipo
    if type == Enums.QuantType.Traj
        name = 'quant_traj';
    elseif type == Enums.QuantType.Sim
        name = 'quant_sim';
    else
        error('campo quant_* invalido!');
    end

    % ler valor de quant pelo tipo
    if isfield(config, name)
        quant = config.(name);
    else 
        quant = -1;
    end

    % retornar se o campo nao existe
    if quant < 0
        return;
    end
    
    % calcular quantizacao
    for i = 1:numel(Ts)
        tsi = Ts_out(i);
        resto = mod(tsi, quant);
        Ts_out(i) = tsi - resto;
    end
end
