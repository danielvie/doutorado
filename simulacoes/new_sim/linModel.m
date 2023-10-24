function [Phi,Gamma] = linModel(A,b,Omega,xbar0,Dt)

% Saídas: Matrizes Phi, Gamma do modelo linearizado
%
% Entradas:
%
% A, b : Cell arrays com as matrizes A e os vetores b correspondentes aos
%        modos de chaveamento
% Omega : Sequência de modos de chaveamento empregada
% xbar0 : Estado inicial do ciclo
% Dt : Intervalos de tempo entre os instantes de chaveamento

N = length(A); % Number of switchings within a cycle
n = size(A{1},1);

% Fa matrices
for j = 1:N
    Aa{j} = [A{Omega(j)} b{Omega(j)};zeros(1,n) 0];
    Fa{j} = expm(Aa{j}*Dt(j));
end

% Phi matrix
Phia = Fa{1};
for j = 2:N
    Phia = Fa{j}*Phia;
end
Phi = Phia(1:end-1,1:end-1);

% Gamma matrix
for i = 1:N
    aux = [xbar0;1];
    for j = 1:N
        if j == i
            aux = Aa{i}*aux;
        end
        aux = Fa{j}*aux;
    end
    GammaDa(:,i) = aux;
end
GammaD = GammaDa(1:end-1,:);

col = [1;-1;zeros(N-2,1)];
row = [1 zeros(1,N-2)];
Gamma = GammaD*toeplitz(col,row);