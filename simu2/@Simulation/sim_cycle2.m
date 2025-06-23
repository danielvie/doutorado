function [y,t,m,xr] = sim_cycle2(~, config)

    x0    = config.x0;
    Ts    = config.Ts;

    nmodes  = numel(config.Omega);
    nstates = numel(x0);
    
    % allocating output vectors
    t    = zeros(nmodes, 1);
    y    = zeros(nmodes, nstates);
    m    = zeros(nmodes, 1);
    
    % computing simulation
    xi0_ = x0;
    
    xr   = zeros(nmodes+1, nstates);
    xr(1,:) = x0;
    
    zeros_aug = [zeros(1, size(config.A{1}, 2)), 0];
    
    for i = 1:nmodes

        % reading operation modes (indices start with `0`)
        imode = config.Omega(i);
                
        % reading matrices `A` and `B`
        Ai = config.A{imode};
        Bi = config.b{imode};
        
        xr(i+1,:) = xi0_;

        % simulating with extended state
        dt   = Ts(i+1) - Ts(i);
        Fa   = expm([Ai,Bi; zeros_aug]*dt);

        % computing propagation
        yend = Fa*[xi0_; 1];

        % saving values of extended state
        y(i,:) = yend(1:nstates)';
        t(i) = Ts(i+1);
        m(i) = imode;

        xi0_  = yend(1:nstates);
    end
end