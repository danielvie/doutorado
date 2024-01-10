function vout =  teste_sanidade(nciclos_in)
    %{
        funcao que calcula x(tn) = F(n-1)*F(n-2)*...*F(0)*x_0 + c
        para patino1(buck-boost), e patino2(multilevel)
        
        como executar:
            vout = teste_sanidade()
                :: executa a funcao com 100 ciclos e retorna as variaveis internas em `vout`

            vout = teste_sanidade(nciclos) 
                :: executa a funcao com `nciclos` ciclos e retorna as variaveis internas em `vout`
                :: nciclos deve ser um numero inteiro
                :: ex: vout = teste_sanidade(1000);
    %}

    nciclos = 100;
    if nargin == 1
        nciclos = nciclos_in;
    end

    % PATINO 1 :: buck-boost converter
    % =====================================================
    
    % carregando configuracao para a simulacao patino 2
    config1 = engine.get_config_sim_patino_1();
    
    % rodando 100 ciclos
    x0 = [12.04; -0.61;];
    label = sprintf("patino1 (%d ciclos)", nciclos);
    [X1, xbar1] = roda_propagacao(config1, x0, nciclos, label);

    figure(1);
    grafico1(X1, xbar1, label);
    

    % PATINO 2 :: multilevel converter
    % =====================================================
    
    % carregando configuracao para a simulacao patino 2
    config2 = engine.get_config_sim_patino_2();
    
    % rodando 100 ciclos
    x0 = [7.51; 20.82; 0.03];
    label = sprintf("patino2 (%d ciclos)", nciclos);
    [X2, xbar2] = roda_propagacao(config2, x0, nciclos, label);

    figure(2);
    grafico2(X2, xbar2, label);

    % lendo variaveis do escopo e retornando como uma estrutura
    % =====================================================
    vout = struct();
    vnames = who;
    for i = 1:numel(vnames)
        vi = vnames{i};
        vout.(vi) = eval(vi);
    end
end

function grafico1(X, xbar, label)
    clf;
    plot(X(1, :), X(2, :));
    hold on;
    plot(xbar(1), xbar(2), 'ro');
    hold off;

    grid on;
    title(label);
    xlabel('x_1');
    ylabel('x_2');

    legend('Xi', '$\bar{X}$', 'interpreter', 'latex');
    set(gca,'fontsize', 16);
end

function grafico2(X, xbar, label)
    clf;
    plot3(X(1, :), X(2, :), X(3, :));
    hold on;
    plot3(xbar(1), xbar(2), xbar(3), 'r*', 'linew', 2, 'markers', 12);
    hold off;

    grid on;
    title(label);
    xlabel('x_1');
    ylabel('x_2');
    zlabel('x_3');
    
    legend('Xi', '$\bar{X}$', 'interpreter', 'latex');
    set(gca,'fontsize', 16);
end

function [XX, xbar] = roda_propagacao(config, x0, nciclos, label)

    [FF, c] = calcula_FF_c(config);

    % calculando x_bar
    xbar = engine.get_xr(config);
    xbar = xbar(1,:)';

    % rodando ciclos
    X  = x0;
    
    XX = zeros(numel(X), nciclos);
    for i = 1:nciclos
        X = FF*X + c;

        XX(:, i) = X(:);
    end

    disp(' ');
    fprintf('X final (%s):\n', label);
    disp(X);
    fprintf('X_bar (%s):\n', label);
    disp(xbar);
    fprintf('X - X_bar (%s):\n', label);
    disp(X - xbar);

end


function [FF, c] = calcula_FF_c(config)
    %{
        usando equacao 2.10 da tese
            x(tn) = F(n-1)*F(n-2)*...*F(0)*x_0 + c == FF*x_0 + c
            
        com 
            FF = F(n-1)*F(n-2)*...*F(0)
            c = F(n-1)F(n-2)...F1g0 + F(n-1)F(n-2)...F2g1 + ... + F(n-1)g(n-2) + g(n-1)

            [Fi, Gi] = c2dm(Ai, bi, [], [], dt, 'zoh')
    %}

    % copiando config para nova var
    cfg = config;

    % inicializando variaveis de apoio
    n = numel(cfg.Omega);
    F = cell(n, 1);
    g = cell(n, 1);
    
    [m_,n_] = size(cfg.A{1});
    I = eye(m_,n_);

    % calculando F e g
    for i = 1:n
        mi = cfg.Omega(i);
        Ai = cfg.A{mi};
        bi = cfg.b{mi};

        % calculando `Fi` e `gi` por estado aumentado
        %  Aa = [ Ai, bi
        %          0,  0]
        dt   = cfg.Ts(i+1) - cfg.Ts(i);
        Fa   = expm([Ai, bi;zeros(1, size(Ai, 2)), 0]*dt);
        F{i} = Fa(1:m_, 1:n_);
        g{i} = Fa(1:m_, n_+1:end);
    end

    % calculando `c`
    %       c = F(n-1)F(n-2)...F1g0 + F(n-1)F(n-2)...F2g1 + ... + F(n-1)g(n-2) + g(n-1)
    %
    c = g{n};
    for i = 2:n
        FFi = I;
        for j = n:-1:i
            FFi = FFi * F{j};
        end
        
        c  = c + FFi*g{i-1};
    end

    % calculando `FF`
    %       FF = F(n-1)F(n-2)...F1
    %
    FF = I;
    for i = n:-1:1
        FF = FF * F{i};
    end

end