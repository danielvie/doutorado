s = Simulation(Enums.SimName.LAB_CIRCUIT);

s.set_mpc_with_np(5);

Phi = s.m_config.mpc.vars.Phi;
Gamma = s.m_config.mpc.vars.Gamma;

% CONSTRUINDO MODELO EXTENDIDO
% notes for LAB_CIRCUIT
% e(tn) = Phi e(t0) + Gamma deltat
% Phi [3x3]
% Gamma [3x5]
% deltat [5x1]

Nd = 3;

% Calculando A,B block
% Ab = A^Nd
Ab = eye(size(Phi));
for i = 1:Nd
    Ab = Ab*Phi;
end

% Bb = (A^(Nd-1) + A^(Nd-1) + ... + A^0)B
B_aux = cell([1, Nd]);
B_aux{1} = eye(size(Phi));
for i = 1:Nd-1
    B_aux{i+1} = Phi*B_aux{i};
end

Bb = B_aux{1}*Gamma;
for i = 2:numel(B_aux)
    Bb = Bb + B_aux{i}*Gamma;
end


% Calculando Matrix Extendida (Aa, Ba)
% Phi [3x3]
% Gamma [3x5]
% deltat [5x1]

Aa = [Ab, Bb
      zeros(1, size(Ab, 2)), zeros(1, size(Bb, 2))];
      
Ba = [zeros(1, size(Gamma, 2)); ones(1, size(Gamma, 2))];


[a_, b_] = Mpc.build_augmented_model(Phi, Gamma, Nd);