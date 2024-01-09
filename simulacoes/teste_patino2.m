
x0_1 = [7.51; 20.82; 0.03];
x0_2 = [9.31; 19.52; 0.73];

xref = [10; 20; 1];

%{

    usando equacao 2.10 da tese

        x(tn) = F(n-1)*F(n-2)*...*F(0) + c
        
    com 
    
        c = F(n-1)F(n-2)...F1g0 + F(n-1)F(n-2)...F2g1 + ... + F(n-1)g(n-2) + g(n-1)
        
        [Fi, Gi] = c2dm(Ai, Bi, [], [], dt, 'zoh')

%}
        
% carregando configuracao para a simulacao
config = engine.get_config_sim_patino_2();

% inicializando variaveis de apoio
n = numel(config.Omega);
F = cell(n, 1);
g = cell(n, 1);
I = eye(size(config.A{1}));

% calculando F e g
for i = 1:n
    mi = config.Omega(i);
    Ai = config.A{mi};
    bi = config.b{mi};

    dt = config.Ts(i+1) - config.Ts(i);
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
FF = eye(size(config.A{1}));
for i = n:-1:1
    FF = FF * F{i};
end

fim = 1000;
X = x0_1;

for i = 1:fim
    X = FF*X + c;
end

xbar = engine.get_xr(config);
xbar = xbar(1,:)';

disp('final do primeiro x0')
disp(X);
disp(xbar);
disp(X - xbar);