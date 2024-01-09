function vout =  teste_sanidade(nciclos_in)

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
    config = engine.get_config_sim_patino_2();
    
    % rodando 100 ciclos
    x0 = [7.51; 20.82; 0.03];
    label = sprintf("patino2 (%d ciclos)", nciclos);
    [X2, xbar2] = roda_propagacao(config, x0, nciclos, label);

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
    xlabel('x1');
    ylabel('x2');

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
    xlabel('x1');
    ylabel('x2');
    zlabel('x3');
    
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
            x(tn) = F(n-1)*F(n-2)*...*F(0) + c
            
        com 
            c = F(n-1)F(n-2)...F1g0 + F(n-1)F(n-2)...F2g1 + ... + F(n-1)g(n-2) + g(n-1)

            [Fi, Gi] = c2dm(Ai, Bi, [], [], dt, 'zoh')
    %}

    % copiando config para nova var
    cfg = config;

    % inicializando variaveis de apoio
    n = numel(cfg.Omega);
    F = cell(n, 1);
    g = cell(n, 1);
    I = eye(size(cfg.A{1}));

    % calculando F e g
    for i = 1:n
        mi = cfg.Omega(i);
        Ai = cfg.A{mi};
        bi = cfg.b{mi};

        dt = cfg.Ts(i+1) - cfg.Ts(i);
        [Fi, gi] = c2dm(Ai, bi, [], [], dt, 'zoh');
        
        F{i} = Fi;
        g{i} = gi;
    end

    % calculando `c`
    %       c = F(n-1)F(n-2)...F1g0 + F(n-1)F(n-2)...F2g1 + ... + F(n-1)g(n-2) + g(n-1)
    %
    c = 0;
    for i = 2:n
        FFi = I;
        for j = n:-1:i
            FFi = FFi * F{j};
        end
        
        c  = c + FFi*g{i-1};
    end
    c = c + g{n};

    % calculando `FF`
    %       FF = F(n-1)F(n-2)...F1
    %
    FF = eye(size(cfg.A{1}));
    for i = n:-1:1
        FF = FF * F{i};
    end

end