function [y, t, m, u, xr] = sim_cycle_dense(~, config)
    % sim_cycle_dense - Delegates to Dynamics.propagate_dense
    [y, t, m, u, xr] = Dynamics.propagate_dense(config);
end
