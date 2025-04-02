function set_alpha_and_mpc(self, alpha)

    self.set_traj_phase_with_alpha(alpha);
    self.set_mpc();
        
    time_us = arrayfun(@round, diff(self.config.Ts*1e6));
    mode = self.config.Omega-1;
    disp(time_us);
    disp(mode);
    
    Helpers.signal_create(time_us, mode)
    
end