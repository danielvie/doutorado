function [A, b] = get_simbolic_patino_2(ini) 

    if (nargin == 0)
        ini = 1;
    end

    clc;
    syms R C1 C2 L

    % montando valores de matrizes
    A = cell(1,8);
    b = cell(1,8);
    for i = 1:8
        ibin = dec2bin(i-1, 3);
        u1 = str2double(ibin(1));
        u2 = str2double(ibin(2));
        u3 = str2double(ibin(3));

        A{i} = [ 0, 0, (u2 - u1)/C1;
                 0, 0, (u3 - u2)/C2;
                 (u1-u2)/L, (u2-u3)/L, -R/L];

        b{i} = [0;0;-R/L*u3];


        % imprimindo valores
        if (i >= ini)
            ai = A{i};
            fprintf("A_%d [%d, %d, %d]: \n\n", i, u1, u2, u3);
            disp(ai);
        end
    end

end
