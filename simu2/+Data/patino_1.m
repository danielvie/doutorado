%%
% --------------------------------------
% CONFIG
% --------------------------------------

function config = patino_1()

      config = Data.Config();

      % simulation name 
      config.sim_name = Enums.SimName.PATINO_1;

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

      % time step of the simulation
      config.tstep = 1e-5;
      
      % reference state vector (vc_ref, il_ref)
      config.xref  = [2, -1];

      % weighting matrix for the trajectory computation
      config.Q     = diag([1,1]);

	% max value for the period of the trajectory cycle
      config.Tpmax = 1;

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

      % constraint time
      % config.c_time = [0.001, 0.001];
      config.c_time = [0.2515, 0.2500-0.04];
end