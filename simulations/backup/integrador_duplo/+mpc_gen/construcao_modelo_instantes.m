function [Phi, Gamma] = construcao_modelo_instantes(Ac,Bc,tr,ur)

% tr = [tr1, tr2, ..., trN]
% Assume-se tr0 = 0 e, portanto, T = trN
% ur = [ur(tr0), ur(tr1), ..., ur(trN-1)]

N = length(tr);
T = tr(N);
Dur = diff(ur); % Dur = [Dur1, Dur2, ..., DurN-1 ]

% Phi = expm(Ac*T);
tam = numel(Ac);
Phi = eye(size(Ac{1}));
Ts  = get_ts(tr);
Fr  = cell(tam, 1);
for i = 1:tam
    Fr{i} = expm(Ac{i}*(Ts(i+1)-Ts(i)));
    Phi   = Phi*Fr{i};
    
    % Phi = Phi*expm(Ac{i}*T);
end

% for i = 1:(N-1)
%     Ai = expm(Ac*(tr(N) - tr(i)));
%     Gamma(:,i) = -Ai*Bc*Dur(i);
% end

Xr = get_xr();

for i = 1:(N-1)
%     Gri = expm(Ac{i}*(Ts(i+1)-Ts(i)))*(Ts(i+1)-Ts(i));
    Gri = Fr{i}*Bc{i}*(Ts(i+1)-Ts(i));
    
    Gamma(:,i) = Fr{i}*Ac{i}*Xr(i,:)' - Fr{i+1}*Ac{i+1}*Xr(i+1,:)' + Ac{i}*Gri + Bc{i} - Fr{i+1}*Bc{i+1};
    
%     Ai = expm(Ac{i}*(tr(N) - tr(i)));
%     Gamma(:,i) = -Ai*Bc{i}*Dur(i);
%     bla = 1;
end

