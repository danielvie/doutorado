function set_config(self, sim_name)

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
        otherwise
            disp('value not valid')
    end

end