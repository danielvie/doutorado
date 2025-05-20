function [Aa, Ba] = construcao_modelo_aumentado(Phi, Gamma, Nd)
    % construcao_modelo_aumentado - compute the extended model for the propagation
    % matrices for a block of commants contidering a delay in the control command
    % 
    % Syntax: [Aa, Ba] = Mpc.construcao_modelo_aumentado(Phi, Gamma, Nd)
    %
    % Inputs:
    %   Phi - Matrix of propagation dynamics
    %   Gamma - Matrix of propagation control
    %   Nd - Number of delays in the block (repeated control)
    %
    % Outputs:
    %   Aa - Matrix of propagation dynamics (block)
    %   Ba - Matrix of propagation control (block)

    % CONSTRUINDO MODELO EXTENDIDO
    % notes for LAB_CIRCUIT
    % e(tn) = Phi e(t0) + Gamma deltat
    % Phi [3x3]
    % Gamma [3x5]
    % deltat [5x1]

    % Nd = 3;

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
    %
    % Xa[k'+1] = Aa X[k'] + Bb z[k']
    %
    % k' = unit blocks of Nd
    % z[k'] = u[k'+1] => u[k'] = z[k'-1]
    % Xa[k'] = [X[k'];z[k'-1]]
    % 
    % Aa = [Ab, Bb; 
    %       za, zb]
    % Ba = [0; 
    %       1]
    %
    % Ab [na,ma]
    % Bb [nb,mb]
    % za [na,ma]
    % zb [na,mb]

    [~,ma] = size(Ab);
    [~,mb] = size(Bb);
    za = zeros(mb,ma);
    zb = zeros(mb,mb);

    Aa = [Ab, Bb
          za, zb];
        
    Ba = [zeros(ma, mb); ones(mb, mb)];
end