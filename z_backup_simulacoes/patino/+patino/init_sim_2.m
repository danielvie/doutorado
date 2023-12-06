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

function config = init_sim_2()
	% equacoes de estado Buck-Boost converter
	R  = 10.0; % Ω
	L  = 10.0*1e-3; % mH
	C1 = 40.0*1e-6; % μF
	C2 = 40.0*1e-6; % μF
	E  = 30.0; % V

	A0  = [
		0, 0, 0
        0, 0, 0
        0, 0, -R/L
	];
	
	A1  = [
		0, 0, 0
        0, 0, 1/C2
        0, -1/L, -R/L
	];
	
	A2  = [
		0, 0, 1/C1
        0, 0, -1/C2
        -1/L, 1/L, -R/L
	];

	A3  = [
		0, 0, 1/C1
        0, 0, 0
        -1/L, 1/L, -R/L
	];

	A4  = [
		0, 0, -1/C1
        0, 0, 0
        1/L, 0, -R/L
	];

	A5  = [
		0, 0, -1/C1
        0, 0, 1/C2
        1/L, -1/L, -R/L
	];

	A6  = [
		0, 0, 0
        0, 0, -1/C2
        0, 1/L, -R/L
	];

	A7  = [
		0, 0, 0
        0, 0, 0
        0, 0, -R/L
	];

	B0 = [0; 0; 0];

	B1 = [0; 0; E/L];

	B2 = [0; 0; 0];

	B3 = [0; 0; E/L];

	B4 = [0; 0; 0];

	B5 = [0; 0; E/L];

	B6 = [0; 0; 0];

	B7 = [0; 0; E/L];
		
	Cc = eye(3);

	Dc = [0;0;0];

	vc1ref = 2/3*E;
	vc2ref = 1/3*E;
	ilref  = 1;

	config.modes = [0, 1, 3, 7, 2, 0, 4, 7, 4];
    config.ur    = [1, 1, 1, 1, 1, 1, 1, 1, 1];
    
	config.Ac    = {A0, A1, A2, A3, A4, A5, A6, A7};
	config.Bc    = {B0, B1, B2, B3, B4, B5, B6, B7};
	config.Cc    = Cc;
	config.Dc    = Dc;

	config.tstep = 1e-6;
	config.xref  = [vc1ref, vc2ref, ilref];
	
	config.Q     = diag([10, 5, 20000]);
	config.Tpmax = 0.4*1e-3; % 0.4ms
    config.tmin  = 0.022*1e-3; % 0.022 ms
    
	config.smax  = 12;
    
    config.Ts    = [0.000, 0.066, 0.088, 0.110, 0.132, 0.154, 0.220, 0.242, 0.264, 0.286]*1e-3;
	config.x0    = [9.9247, 19.2928, 0.9823];
			
end