function [Sf,bf,Si,bi] = determina_oinf(Af,Gamma,Spsi,bpsi,max_iter,tol)

% [Sf,bf,Si,bi] = determina_oinf(Af,Gamma,Spsi,bpsi,max_iter,tol)
%
% max_iter --> No. maximo de iteracoes
% tol > 0 --> Tolerancia no teste de redundancia
%            (default = 0)

% Inicializacao
if nargin < 6, tol = 0; end

r = length(bpsi); % No. restricoes
SpsiGamma = Spsi*Gamma;
S = SpsiGamma; b = bpsi;
flag_redund = 0;
i = 1;

while ( (i <= max_iter) && (flag_redund == 0) )
    disp(['Iteracao ' num2str(i) ' / ' num2str(max_iter)])
    Si{i} = S; bi{i} = b; % Update: 01 Sep 2022
    flag_redund = 1; % Se esse flag nao for mudado, o algoritmo sera encerrado
                     % pois todas as novas restricoes serao redundantes
    SGAi = SpsiGamma*(Af^i);
    for j = 1:r % Teste de redundancia de cada restricao
        c = SGAi(j,:)';
        d = bpsi(j);
        % A restricao eh redundante se e somente se t(j) <= tol 5
        t(j) = teste_redundancia(S,b,c,d);
        if t(j) > tol % Se a restricao nao for redundante
            flag_redund = 0; % Pelo menos uma restricao nao foi redundante
            % Agrega-se essa restricao aas anteriores
            S = [S;c']; b = [b;d];
        end
    end
    i = i + 1;
end

% Finalizacao
if (flag_redund == 0) % O algoritmo foi encerrado sem que houvesse redundancia das restricoes
    disp('nao foi possivel caracterizar o MAS')
    Sf = []; bf = [];
else
    Sf = S; bf = b;
end