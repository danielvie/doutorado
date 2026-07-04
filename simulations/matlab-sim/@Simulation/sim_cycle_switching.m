function [y, t, m, xr] = sim_cycle_switching(~, config)
    % sim_cycle_switching - Delegates to Dynamics.propagate_switching
    [y, t, m, xr] = Dynamics.propagate_switching(config);
end
