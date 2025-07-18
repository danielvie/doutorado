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

function config = lab_circuit()

	% simulation name 
	config.sim_name = Enums.SimName.LAB_CIRCUIT;

	% operation modes (alpha = 0.5)
	config.Omega = [5, 7, 3, 4, 2, 6];

	% maximum number of operation modes
	config.smax  = 12;

	% dynamics of the system (Buck-Boost converter)
	config.circuit_params.E  = 5.0; % V
	config.circuit_params.C1 = 470.0*1e-6; % μF
	config.circuit_params.C2 = 470.0*1e-6; % μF
	config.circuit_params.L  = 100.0*1e-3; % mH
	config.circuit_params.R  = 22.0 + 2.0; % Ω
	
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
    config.Ts    = [0.0, 46.6667, 93.3333, 140.0, 186.6667, 233.3333, 280.0]*1e-6;
	
	% initial state
    config.x0    = [1.0000; 2.0062; 0.0626];

    % constraint time (t_min)
    config.c_time = [1, 1]*(3*1e-6);

	% % config OTMIN
	% % tmin   = 0.022*1e-3;
	% % tmax   = 0.400*1e-3;
	% % x0     = [diff(config.Ts), config.x0];
	% % lb     = [ones(1, ndt)*0.022*1e-3, config.x0 - [1, 1, 0.1]];
	% % ub     = [ones(1, ndt)*0.088*1e-3, config.x0 + [1, 1, 0.1]];
	% Ndt              = numel(config.Ts) - 1; % nro de elementos dt
	% config.otmin     = struct();
	% config.otmin.x0  = ones(Ndt, 1)*0.044*1e-3;
	% config.otmin.lb  = ones(Ndt, 1)*0.022*1e-3; %[22e-6, 22e-6, ..., 22e-6]
	% config.otmin.ub  = ones(Ndt, 1)*config.Tpmax;
	% config.otmin.A   = ones(1, Ndt);
	% config.otmin.b   = config.Tpmax;
	% config.otmin.Aeq = [];
	% config.otmin.beq = [];

end
