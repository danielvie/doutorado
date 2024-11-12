%%
% --------------------------------------
% CONFIG
% --------------------------------------

function config = get_config_sim_intduplo()
      
      % simulation name 
      config.sim_name = enums.SimName.INTEGRADOR_DUPLO;

      % operation modes
      config.Omega  = [1, 2, 3, 2]; % modo de operacao

      % maximum number of operation modes
      config.smax  = 4;

      % dynamics of the system
      A = [0, 1;0, 0];
      b_1 = [0;  1];
      b_2 = [0;  0];
      b_3 = [0; -1];

      C = eye(2);
      D = [0;0];

      % config.ur     = [1, 0, 1, 0]; % controle associado com modo
      
      config.A = {A, A, A};
      config.b = {b_1, b_2, b_3};
      config.C = C;
      config.D = D;

      % time step of the simulation
      config.tstep = 0.01;

      % reference state vector
      % [pos, vel]
      config.xref  = [2, -1];

      % weighting matrix for the trajectory computation
      config.Q = diag([1,1]);

	% max value for the period of the trajectory cycle
      config.Tpmax = 1;

      % time sequence
      config.Ts    = [0, 2, 3, 5, 6];
      
      % initial state
      config.x0    = [-0.5; -1];

end