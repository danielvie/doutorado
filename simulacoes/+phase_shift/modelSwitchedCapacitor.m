function [A,b] = modelSwitchedCapacitor(n,R,L,C,E)

    % [A,b] = modelSwitchedCapacitor(n,R,L,C,E)
    % n = Number of switching cells
    % C = [C1 C2 ... Cn-1]

    nModes = 2^n; % Total number of possible modes
    for i = 1:nModes
        ubin = dec2bin(i-1,n);
        for j = 1:n
            u(j) = str2num(ubin(j)); % State of the jth cell
        end
        
        auxA = zeros(n,n);
        for j = 1:n-1
            auxA(j,n) = (u(j+1) - u(j))/C(j);
            auxA(n,j) = (u(j) - u(j+1))/L;
        end
        auxA(n,n) = -R/L;
        A{i} = auxA;
        
        auxb = zeros(n,1);
        auxb(n) = u(n)*E/L;
        b{i} = auxb;
    end
end