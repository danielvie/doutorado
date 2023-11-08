%%
% --------------------------------------
% CONFIG
% --------------------------------------

function config = get_config_sim_patino_1()

      % operation modes
      config.Omega  = [1, 2];

      % maximum number of operation modes
      config.smax  = 2;

      % dynamics of the system
      R = 1;
      L = 1;
      C = 1;
      E = 1;

      A1 = [0,0
            0, -1/(R*C)];
      A2 = [   0,    1/L
            -1/C, -1/(R*C)];

      B1 = [E/L; 0];
      B2 = [0; 0];

      C = eye(2);
      D = [0;0];

      config.A = {A1, A2};
      config.b = {B1, B2};
      config.C = C;
      config.D = D;

      % #FIXME: not sure this is being used
      % config.ur     = [1, 0]; % controle associado com modo

      % time step of the simulation
      config.tstep = 1e-5;
      
      % reference state vector (vc_ref, il_ref)
      config.xref  = [2, -1];

	% #FIXME: check if this is still valid
	% minumum value of the time increament
      config.tmin  = 0.25;
      
      % weighting matrix for the trajectory computation
      config.Q     = diag([1,1]);

	% max value for the period of the trajectory cycle
      config.Tpmax = 1;

      % ??? #FIXME: check if this is still used
      % config.r     = r;
      
      % time sequence
      config.Ts    = [0., 0.2514520, 0.5014520];

      % initial state
      config.x0    = [1.870801; -1.119853];
      
      % config OTMIN
      config.otmin     = struct();
      config.otmin.x0  = [0.25, 0.25];
      config.otmin.lb  = [0.25, 0.25];
      config.otmin.ub  = [1.50, 1.50];
      config.otmin.A   = [];
      config.otmin.b   = [];
      config.otmin.Aeq = [];
      config.otmin.beq = [];
end