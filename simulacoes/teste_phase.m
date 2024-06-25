function teste_phase()

    % get configuration
    config = engine.get_config_sim_patino_2();
    iref = 1.0; 

    cfg = compute_phase(config, iref);
    
    disp(cfg);

end