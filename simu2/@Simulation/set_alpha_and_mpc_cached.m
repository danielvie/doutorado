function set_alpha_and_mpc_cached(self, alpha)
    persistent cache;

    if isempty(cache)
        cache = containers.Map('KeyType', 'double', 'ValueType', 'any');
    end
    
    % define key
    key = alpha;

    % check if key exists in cache
    if isKey(cache, key)
        cached_data = cache(key);

        self.config = cached_data.config;
        self.mpc = cached_data.mpc;
        disp(["got data from cache for alpha: ", num2str(alpha)]);
    else 
        self.set_traj_phase_with_alpha(alpha);
        self.set_mpc();
        
        cache(key) = struct('config', self.config, 'mpc', self.mpc);
        fprintf("cached alpha %.3f: ", key);
    end
    
    fprintf("\n");
    time_us = arrayfun(@round, diff(self.config.Ts*1e6));
    mode = self.config.Omega-1;
    disp(time_us);
    disp(mode);
    
    Helpers.signal_create(time_us, mode)
    
end