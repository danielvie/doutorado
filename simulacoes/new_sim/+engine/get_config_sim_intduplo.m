%%
% --------------------------------------
% CONFIG
% --------------------------------------

function config = get_config_sim_intduplo()
      % equacoes integrador duplo
      A = [0, 1;0, 0];
      b = [0; 1];
      C = eye(2);
      D = [0;0];

      tmin  = 0.25;
      xref  = [2, -1];
      % xref: [vc_ref; il_ref]

      Q     = diag([1,1]);
      Tpmax = 1;
      smax  = 2;
      r     = 1;
      % r: 

      config.Omega  = [1, 2, 3, 4]; % modo de operacao
      config.ur     = [1, 0, 1, 0]; % controle associado com modo
      
      config.A = {A, A, A, A};
      config.b = {b, b*0, -b, b*0};
      config.C = C;
      config.D = D;
      
      config.tstep = 0.01;
      config.xref  = xref;
      config.tmin  = tmin;
      config.Q     = Q;
      config.Tpmax = Tpmax;
      config.smax  = smax;
      config.r     = r;
      
      config.Ts    = [0, 2, 3, 5, 6];
      config.x0    = [-0.5; -1];
      
end