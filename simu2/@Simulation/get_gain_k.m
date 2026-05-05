function gain_k = get_gain_k(self)
    if isempty(self.m_config.mpc) || ~isfield(self.m_config.mpc, 'K')
        error('MPC gain is not configured. Call set_mpc(options) first.');
    end
    gain_k = self.m_config.mpc.K;
end
