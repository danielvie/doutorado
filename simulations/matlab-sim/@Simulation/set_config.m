function success = set_config(self, sim_name)

    success = true;
    switch sim_name
        case Enums.SimName.INTEGRADOR_DUPLO
            disp('loading config `double integrator`');
            self.m_config = Data.double_integrator();
        case Enums.SimName.PATINO_1
            disp('loading config `patino_1`');
            self.m_config = Data.patino_1();
        case Enums.SimName.PATINO_2
            disp('loading config `patino_2`');
            self.m_config = Data.patino_2();
        case Enums.SimName.LAB_CIRCUIT
            disp('loading config `lab_circuit`');
            self.m_config = Data.lab_circuit();
        otherwise
            success = false;
            disp('ERROR: `sim_name` value not valid as an argument')
    end

end