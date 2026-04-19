
% demo de como criar projecao da regiao de atracao

% 1. Acao: Criar objeto de simulacao com configuracao desejada
%    Esperado: o objeto de simulacao deve ser criado com sucesso
%    Nota: as opcoes de configuracao estao em Enums.SimName sao 
%          -> Enums.SimName.INTEGRADOR_DUPLO *nao computa phase
%          -> Enums.SimName.PATINO_1 *nao computa phase
%          -> Enums.SimName.PATINO_2
%          -> Enums.SimName.LAB_CIRCUIT
s = Simulation(Enums.SimName.LAB_CIRCUIT);

% 2. Acao: (para PATINO_2 e LAB_CIRCUIT) Configurar o modelo com alpha desejado
%    Esperado: o modelo deve ser configurado com alpha desejado
s.set_traj_phase_with_alpha(0.5);

% 3. Acao: Execute o comando de projecao
%    Esperado: o grafico com a projecao deve aparecer na tela
%    Nota: codigo fonte de `project_feasibility_region` esta em
%          ./simu2/@Simulation/project_feasibility_region.m
s.project_feasibility_region();