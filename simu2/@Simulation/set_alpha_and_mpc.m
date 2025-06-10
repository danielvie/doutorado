function set_alpha_and_mpc(self, alpha)

    self.set_traj_phase_with_alpha(alpha);
    self.set_mpc();
        
    time_us = arrayfun(@round, diff(self.m_config.Ts*1e6));
    mode = self.m_config.Omega-1;
    disp(time_us);
    disp(mode);
    
    Utils.signal_create(time_us, mode)
    
end