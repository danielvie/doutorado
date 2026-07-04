function [Phi, Gamma] = construcao_modelo_instantes(Ac,Bc,tr,ur)

% tr = [tr1, tr2, ..., trN]
% Assume-se tr0 = 0 e, portanto, T = trN
% ur = [ur(tr0), ur(tr1), ..., ur(trN-1)]

N = length(tr);
T = tr(N);
Dur = diff(ur); % Dur = [Dur1, Dur2, ..., DurN-1 ]

Phi = expm(Ac*T);

for i = 1:(N-1)
    Ai = expm(Ac*(tr(N) - tr(i)));
    Gamma(:,i) = -Ai*Bc*Dur(i);
end