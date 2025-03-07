function [y,t,m,xr] = sim_cycle2(~, config)

    % reading config
    cfg = config;

    x0    = cfg.x0;
    Ts    = cfg.Ts;

    nmodes  = numel(cfg.Omega);
    nstates = numel(x0);
    
    % allocating output vectors
    t    = zeros(nmodes, 1);
    y    = zeros(nmodes, nstates);
    m    = zeros(nmodes, 1);
    
    % computing simulation
    xi0  = x0;
    xi0_ = x0;
    
    xr   = zeros(nmodes, numel(x0));
    xr(1,:) = x0;
    
    omega = cfg.Omega;
    for i = 1:nmodes

        % reading operation modes (indices start with `0`)
        imode = omega(i);
                
        % reading matrices `A` and `B`
        Ai = cfg.A{imode};
        Bi = cfg.b{imode};
        
        xr(i+1,:) = xi0;

        % simulating with extended state
        xi0_ = reshape(xi0_, [numel(xi0_), 1]);
        dt   = Ts(i+1) - Ts(i);
        Fa   = expm([Ai,Bi;zeros(1,size(Ai,2)),0]*dt);

        yend     = Fa*[xi0_;1];

        % saving values of extended state
        % y    = [y; yend(1:nstates)';];
        % t    = [t; Ts(i+1)];
        % m    = [m; imode];
        y(i,:) = yend(1:nstates);
        t(i) = Ts(i+1);
        m(i) = imode;

        xi0_  = yend(1:nstates);

    end
end