function load(obj, sim_name)
    switch(sim_name)
        case enums.SimName.INTEGRADOR_DUPLO
            obj.config = data.get_config_sim_intduplo();
        case enums.SimName.PATINO_1
            obj.config = data.get_config_sim_patino_1();
        case enums.SimName.PATINO_2
            obj.config = data.get_config_sim_patino_2();
        otherwise
            disp('invalid option!!');
    end
end