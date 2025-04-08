function set_alpha_and_mpc_cached(self, alpha)
    if isempty(self.set_alpha_cache)
        try
            cache_ = load('set_alpha_cache.mat', 'set_alpha_cache');
            self.set_alpha_cache = cache_.set_alpha_cache;
        catch e
            disp(e);
            self.set_alpha_cache = containers.Map('KeyType', 'double', 'ValueType', 'any');
        end
    end
    
    % define key
    key = alpha;

    % check if key exists in cache
    if isKey(self.set_alpha_cache, key)
        cached_data = self.set_alpha_cache(key);

        self.config = cached_data.config;
        self.mpc = cached_data.mpc;
    else 
        self.set_traj_phase_with_alpha(alpha);
        self.set_mpc();
        
        self.set_alpha_cache(key) = struct('config', self.config, 'mpc', self.mpc);
        self.save_set_alpha_cache();
    end
    
    time_us = arrayfun(@round, diff(self.config.Ts*1e6));
    mode = self.config.Omega-1;
    time_str = strjoin(string(time_us), ", ");

    mode_ = arrayfun(@(x) sprintf("%2d", x), mode);
    mode_str = strjoin(mode_, ", ");
    fprintf("time_us: %s\n", time_str);
    fprintf("mode   : %s\n", mode_str);
end