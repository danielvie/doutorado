function result = can_compute_phase(self)
    result = (self.config.sim_name == Enums.SimName.PATINO_2) || ...
             (self.config.sim_name == Enums.SimName.LAB_CIRCUIT);
end