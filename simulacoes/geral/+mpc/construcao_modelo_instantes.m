function [Phi, Gamma] = construcao_modelo_instantes(Ac,Bc,tr,xr)

% tr = [tr1, tr2, ..., trN]'
% Assume-se tr0 = 0 e, portanto, T = trN
% ur = [ur(tr0), ur(tr1), ..., ur(trN-1)]

tr  = reshape(tr, [numel(tr), 1]);

N   = length(tr);
T   = tr(N);
% Dur = diff(ur); % Dur = [Dur1, Dur2, ..., DurN-1 ]

% Phi = expm(Ac*T);
tam = N;
Phi = eye(size(Ac{1}));
Ts  = [0; tr];
Fr  = cell(tam, 1);
for i = 1:tam
    tti   = Ts(i+1);
    ti    = Ts(i);
    
    dti   = tti - ti;
    
    Fr{i} = expm(Ac{i}*dti);
    Phi   = Phi*Fr{i};
end

Xr = xr;
for i = 1:(N-1)
    FF = eye(size(Fr{i}));
    for j = (N):-1:i+1
        FF = FF*Fr{j};
    end
    
%     Gamma(:,i) = FF*(Fr{i}*Ac{i}*Xr(i,:)' + Ac{i}*Gri + Bc{i} + Bc{i+1});
    Gamma(:,i) = FF*((Ac{i}-Ac{i+1})*Xr(i,:)' + Bc{i} - Bc{i+1});
end