function [A, b, C, D] = compute_buckboost(params)
    % reading parameters
	E  = params.E;
	C1 = params.C1;
	C2 = params.C2;
	L  = params.L;
	R  = params.R;
	
    % construction of dynamic matrices
    A = cell(1,8);
    b = cell(1,8);
    
    for i = 1:8
        ibin = dec2bin(i-1, 3);

        u1 = str2double(ibin(1));
        u2 = str2double(ibin(2));
        u3 = str2double(ibin(3));
    
        A{i} = [         0,         0, (u2-u1)/C1
                         0,         0, (u3-u2)/C2
                 (u1-u2)/L, (u2-u3)/L,       -R/L];

        b{i} = [0;0;E/L*u3];
    end
		
	C = eye(3);
	D = [0;0;0];
end