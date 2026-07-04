classdef doc < handle
    %DOC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % configuracoes
        config;
        opt;
        x0;
        lb;
        ub;
        A;
        b;
        Aeq;
        beq;
        
        % resultado otimin
        x;
        fval;
    end
    
    methods
        function o = doc(opcao)
        % classe DOC
        % 
        % opcao: 1 -> inicia exemplo 1, 2 -> inicia exemplo 2

            
            if opcao == 1
                % inicializando objeto com `exemplo 1`
                o.config = doc.init_sim_1();

                % inicializacao configuracao fmincon
                o.opt    = doc.get_otmin_opt(o.config);
                o.x0     = [0.25, 0.25, o.config.x0];
                o.lb     = [0.25, 0.25, o.config.x0 - 2.0];
                o.ub     = [1.50, 1.50, o.config.x0 + 2.0];
                o.A      = [];
                o.b      = [];
                o.Aeq    = [];
                o.beq    = [];
                
            elseif opcao == 2
                % inicializando objeto com `exemplo 2`
                o.config = doc.init_sim_2();
                
                % inicializacao configuracao fmincon
                o.opt    = doc.get_otmin_opt(o.config);
                o.x0     = [0.25, 0.25, o.config.x0];
                o.lb     = [0.25, 0.25, o.config.x0 - 2.0];
                o.ub     = [1.50, 1.50, o.config.x0 + 2.0];
                o.A      = [];
                o.b      = [];
                o.Aeq    = [];
                o.beq    = [];
            else
                error('opcao `%d` invalida!\n', opcao);
            end
        end
        
        function [x, fval] = otimin(o)
            [x, fval] = fmincon(@(x) doc.fun_custo_patino(o.config, x), o.x0, o.A, o.b, o.Aeq, o.beq, o.lb, o.ub, @(x) doc.nonlincon_patino(o.config, x), o.opt);
            
            o.x    = x;
            o.fval = fval;
        end
    end
end

