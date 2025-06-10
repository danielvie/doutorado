function result = can_compute_phase(self)
    result = (self.m_config.sim_name == Enums.SimName.PATINO_2) || ...
             (self.m_config.sim_name == Enums.SimName.LAB_CIRCUIT);
end