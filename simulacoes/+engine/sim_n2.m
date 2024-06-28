% [y,t,u] = sim_n(config, Ts)
function [y,t,m,dtk_out] = sim_n2(config, nsim)


    % inicializacao variaveis de saida
    nmodes  = numel(config.Omega);
    nstates = numel(config.x0);

    dtk_out = [];

    y = zeros(nsim*nmodes, nstates); 
    t = zeros(nsim*nmodes, 1);
    m = zeros(nsim*nmodes, 1);
    
    cfg = config;

    t0  = 0.0;
    x0  = cfg.x0;
    
    mpc_on = false;
    if isfield(cfg, 'mpc')
        if cfg.mpc.on == 1
            mpc_on = true;
        end
    end
    
    numelx0 = numel(x0);
    i0 = 0;
    for i = 1:nsim
        % dtk = zeros([numel(cfg.Omega)-1, 1]);
        if mpc_on
            
            if isfield(cfg, 'iiref')
                % find value for replacing reference
                iiref = cfg.iiref;
                tempos = iiref.time;
                values = iiref.value;
                
                tam = numel(tempos);
                index = 1;
                for itempo = 1:tam
                    if t0 >= tempos(itempo)
                        index = itempo;
                    end
                end
                
                if i0 ~= index || 1
                    i0 = index;
                    value = values(index);
                    cfg = compute_phase(cfg, value);
                end


            end

            % calculo `ek`
            ek  = reshape(x0, [numelx0,1]) - reshape(cfg.mpc.x_target, [numelx0,1]);

            % calculo comando `dtk`
            [dtk, ~, ~] = mpc.mpc_dualmode_switching(ek,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,cfg.mpc.PhiNp,cfg.mpc.p);

            % aplicando diferenca de tempo calculada pelo controle em cima
            % da trajetoria de referencia.
            % nota: o tempo eh ajustado a partir de `j+1` porque o primeiro
            % instante eh `0`.
            Ts = cfg.Ts;
            
            %Ts = engine.quantizacao(cfg, Ts, engine.QuantType.Sim);

            for j = 1:numel(dtk)
                Ts(j+1) = Ts(j+1) + dtk(j);
            end
    
            cfg.Ts = Ts;
            
        end
        
        % simulando dinamica
        [y_,t_,m_,~] = engine.sim_cycle2(cfg);

        % salvando estados
        ii = (i-1)*nmodes + 1;
        y(ii:ii+nmodes-1,:) = y_(1:nmodes,:);
        t(ii:ii+nmodes-1)   = t_(1:nmodes) + t0;
        m(ii:ii+nmodes-1)   = m_(1:nmodes);

        % salvando acao de controle
        % dtk_out = [dtk_out, dtk];
        dtk_out = [];

        % atualizando valores do prox ciclo
        cfg.x0 = y_(end,:)';
        t0  = t_(end) + t0;
        x0  = cfg.x0;

    end
end
