function FF = get_config(nome)
% get_config - monta strutura `config` para o caso que se deseja simular
% 
% Prototype   : config = get_config(nome)
% Description : more detailed description
% 
% In          : nome - nome do caso que se deseja simular
% 
% Out         : config - estrutura de dados do caso a simular
% 
% Pre. Cond   : nenhuma
% 
% Post. Cond. : nenhuma
%
% Notes       : nenhuma
% 
% --------------------------------------------------------------------------------
% 
%           MATLAB Module
% 
% --------------------------------------------------------------------------------
%
% Author : Daniel Vieira {dvieira}
% 
% History
% 2021-11-30: 1 - dvieira - inicio da funcao

    if nargin == 0
        nome = '';
    end

    F = dir(['+engine' filesep 'get_config_*.m']);
    
    for i = 1:numel(F)
        fi = F(i);

        ni   = regexprep(fi.name, '\.m$', '');
        ni_1 = regexprep(ni, '^get_config_', '');
        ni_2 = regexprep(ni, '^get_config_sim_', '');
        
        if strcmpi(nome, ni_1) || strcmpi(nome, ni_2)
            return;
        end
    end   
    
    % NAO ENCONTREI NADA!
    NF = numel(F);
    for i = NF:-1:1
        FF{i} = regexprep(F(i).name, '\.m$', '');
    end

    op = 0;

    while (op == 0)
        for i = 1:NF
            fprintf("%d. %s\n", i, FF{i});
        end

        fprintf("\n");
        op = input("entre com a opcao: ");

        if (op <= 0) || (op > NF)
            fprintf("opcao nao valida!!!\n");
            op = 0;
            continue;
        end

        % eval funcao
        fun = str2func(['engine.' FF{op}])
        config = fun();
        disp(config);
    end

end