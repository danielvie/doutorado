%{
otmin - chamada da `engine` da otimizacao para o calculo da trajetoria de ciclo limite alvo

Prototype   : [config_new, x, fval] = otmin(config, opt)
Description : funcao optmin executa uma simulacao usando `fmincon` para calcular os valores de `dt` para a trajetoria de ciclo limite alvo.
              
In          : config - strutura de dados `config` com informacao do modelo para fazer a simulacao
              opt    - parametros do `fmincon`

Out         : config_new - `config` atualizado com resultados da simulacao
              x          - resultado da otimizacao 
              fval       - custo assossiado ao resultado `x`

Pre. Cond   : `config` deve ser inicializado usando `engine.get_config` e 

Post. Cond. : post condition(s) that is (are) applicable

Notes       : what else the user needs to know

--------------------------------------------------------------------------------

          MATLAB Module

--------------------------------------------------------------------------------

Author : <author's name>

History
yyyy-mm-dd: <change-id> <author> <change description>

%}

function [config_new, x, fval] = otmin(config, opt)
    config_new = config;
    
    % --------------------------------------
    % FMINCON
    % --------------------------------------
    
    if ~exist('opt', 'var')
        opt    = engine.get_otmin_opt(config_new);
        opt.ConstraintTolerance = 1e-8;
        opt.PlotFcn = 'optimplotfvalconstr';
    end
    
    x0     = config.otmin.x0;
    lb     = config.otmin.lb;
    ub     = config.otmin.ub;
    A      = config.otmin.A;
    b      = config.otmin.b;
    Aeq    = config.otmin.Aeq;
    beq    = config.otmin.beq;
    
    [x, fval] = fmincon(@(x) engine.fun_custo_patino(config_new, x), x0, A, b, Aeq, beq, lb, ub, [], opt);
    
    % atualizando valores
    config_new.Ts = engine.get_ts(x);
    config_new.x0 = engine.get_x0(config_new);
end