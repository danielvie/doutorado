%%
% --------------------------------------
% CONFIG
% --------------------------------------
%{
	Mode	u1 	u2 	u3
	0		0  	0 	0
	1		0  	0 	1
	2		0  	1 	0
	3		0  	1 	1
	4		1  	0 	0
	5		1  	0 	1
	6		1  	1 	0
	7		1  	1 	1
%}

function config = get_config_sim_patino_2()

	% simulation name 
	config.sim_name = enums.SimName.PATINO_2;

	% operation modes
	config.Omega = [1, 2, 4, 8, 3, 1, 5, 8, 5];

	% maximum number of operation modes
	config.smax  = 12;

	% dynamics of the system (Buck-Boost converter)
	R  = 10.0; % Ω
	L  = 10.0*1e-3; % mH
	C1 = 40.0*1e-6; % μF
	C2 = 40.0*1e-6; % μF
	E  = 30.0; % V
	
    % construcao das matrizes dinamica
    A = cell(1,8);
    b = cell(1,8);
    
    for i = 1:8
        ibin = dec2bin(i-1, 3);

        u1 = str2double(ibin(1));
        u2 = str2double(ibin(2));
        u3 = str2double(ibin(3));
    
        A{i} = [        0,         0, (u2-u1)/C1
                         0,         0, (u3-u2)/C2
                 (u1-u2)/L, (u2-u3)/L,       -R/L];

        b{i} = [0;0;E/L*u3];
    end
		
	C = eye(3);
	D = [0;0;0];

	config.A     = A;
	config.b     = b;
	config.C     = C;
	config.D     = D;

	% time step of the simulation
	config.tstep = 1e-6;

	% reference state vector (vc1, vc2, i)
	config.xref  = [1/3*E; 2/3*E; 1];
	
	% weighting matrix for the trajectory computation
	config.Q     = diag([10, 5, 20000]);

	% max value for the period of the trajectory cycle
	config.Tpmax = 0.4*1e-3; % 0.400ms
    
	% time sequence
    config.Ts    = [0.000, 0.066, 0.088, 0.110, 0.132, 0.154, 0.220, 0.242, 0.264, 0.286]*1e-3;
	
	% initial state
    config.x0    = [9.9247; 19.2928; 0.9823];

	% config OTMIN
	% tmin   = 0.022*1e-3;
	% tmax   = 0.400*1e-3;
	% x0     = [diff(config.Ts), config.x0];
	% lb     = [ones(1, ndt)*0.022*1e-3, config.x0 - [1, 1, 0.1]];
	% ub     = [ones(1, ndt)*0.088*1e-3, config.x0 + [1, 1, 0.1]];
	Ndt              = numel(config.Ts) - 1; % nro de elementos dt
	
	config.otmin     = struct();
	config.otmin.x0  = ones(Ndt, 1)*0.044*1e-3;
	config.otmin.lb  = ones(Ndt, 1)*0.022*1e-3; %[22e-6, 22e-6, ..., 22e-6]
	config.otmin.ub  = ones(Ndt, 1)*config.Tpmax;
	config.otmin.A   = ones(1, Ndt);
	config.otmin.b   = config.Tpmax;
	config.otmin.Aeq = [];
	config.otmin.beq = [];
end
