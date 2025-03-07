function success = set_config(self, sim_name)

    success = true;
    switch sim_name
        case Enums.SimName.INTEGRADOR_DUPLO
            disp('loading config `integrador duplo`');
            self.config = Data.intduplo();
        case Enums.SimName.PATINO_1
            disp('loading config `patino_1`');
            self.config = Data.patino_1();
        case Enums.SimName.PATINO_2
            disp('loading config `patino_2`');
            self.config = Data.patino_2();
        case Enums.SimName.LAB_CIRCUIT
            disp('loading config `lab_circuit`');
            self.config = Data.lab_circuit();
        otherwise
            success = false;
            disp('value not valid')
    end

end