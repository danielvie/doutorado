%%
% --------------------------------------
% CONFIG
% --------------------------------------

function config = get_config_sim_matheus()
      % equacoes integrador duplo
      Ac  = [0, 1;0, 0];
      Bc  = [0; 1];

      Cc = eye(2);

      Dc = [0;0];

      tmin  = 0.25;
      xref  = [2, -1];
      % xref: [vc_ref; il_ref]

      Q     = diag([1,1]);
      Tpmax = 1;
      smax  = 2;
      r     = 1;
      % r: 

      config.modes  = [0, 1, 2, 3]; % modo de operacao
      config.ur     = [1, 0, 1, 0]; % controle associado com modo
      
      config.Ac = {Ac, Ac, Ac, Ac};
      config.Bc = {Bc, Bc*0, -Bc, Bc*0};
      config.Cc = Cc;
      config.Dc = Dc;
      
      config.tstep = 1e-5;
      config.xref  = xref;
      config.tmin  = tmin;
      config.Q     = Q;
      config.Tpmax = Tpmax;
      config.smax  = smax;
      config.r     = r;
      
      config.Ts    = [0, 2, 3, 5, 6];
      config.x0    = [-0.5; -1];
end