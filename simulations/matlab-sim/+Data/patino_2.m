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

function config = patino_2()

	config = Data.Config();

	% simulation name 
	config.sim_name = Enums.SimName.PATINO_2;

	% operation modes
	config.Omega = [1, 2, 4, 8, 3, 1, 5, 8, 5];

	% maximum number of operation modes
	config.smax  = 12;

	% dynamics of the system (Buck-Boost converter)
	config.circuit_params.E  = 30.0; % V
	config.circuit_params.C1 = 40.0*1e-6; % μF
	config.circuit_params.C2 = 40.0*1e-6; % μF
	config.circuit_params.L  = 10.0*1e-3; % mH
	config.circuit_params.R  = 10.0; % Ω
	
	% computing dynamic matrix for buckboost
	[A,b,C,D] = Utils.compute_buckboost(config.circuit_params);

	config.A     = A;
	config.b     = b;
	config.C     = C;
	config.D     = D;

	% time step of the simulation
	config.tstep = 1e-6;

	% reference state vector (vc1, vc2, i)
	E = config.circuit_params.E;
	config.xref  = [1/3*E; 2/3*E; 1];
	
	% weighting matrix for the trajectory computation
	config.Q     = diag([10, 5, 20000]);

	% max value for the period of the trajectory cycle
	config.Tpmax = 0.4*1e-3; % 0.400ms
    
	% time sequence
    config.Ts    = [0.000, 0.066, 0.088, 0.110, 0.132, 0.154, 0.220, 0.242, 0.264, 0.286]*1e-3;
	
	% initial state
    config.x0    = [9.9247; 19.2928; 0.9823];

    % constraint time
    config.c_time = [3*1e-6, 3*1e-6];

end
