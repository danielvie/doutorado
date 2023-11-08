%%
% --------------------------------------
% CONFIG
% --------------------------------------

function config = get_config_sim_intduplo()

      % operation modes
      config.Omega  = [1, 2, 3, 4]; % modo de operacao

      % maximum number of operation modes
      config.smax  = smax;

      % dynamics of the system
      A = [0, 1;0, 0];
      b = [0; 1];
      C = eye(2);
      D = [0;0];

      % #FIXME: mudar isso daqui para fazer apenas dois modos de dinamica
      config.ur     = [1, 0, 1, 0]; % controle associado com modo
      
      config.A = {A, A, A, A};
      config.b = {b, b*0, -b, b*0};
      config.C = C;
      config.D = D;

      % time step of the simulation
      config.tstep = 0.01;

      % reference state vector
      % [pos, vel]
      config.xref  = [2, -1];

	% #FIXME: check if this is still valid
	% minumum value of the time increament
      config.tmin  = 0.25;

      % weighting matrix for the trajectory computation
      config.Q = diag([1,1]);

	% max value for the period of the trajectory cycle
      config.Tpmax = 1;

      % time sequence
      config.Ts    = [0, 2, 3, 5, 6];
      
      % initial state
      config.x0    = [-0.5; -1];

end