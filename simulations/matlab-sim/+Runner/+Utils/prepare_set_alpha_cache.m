function prepare_set_alpha_cache()

    s = Simulation();
    success = s.set_config(Enums.SimName.LAB_CIRCUIT);

    if ~success
        error("ERROR: could not set config");
    end
    
    cont = 0;
    freq = 10;
    
    h = waitbar(0, 'Processing...');
    for alpha = 0.01:0.01:0.99
        cont = rem(cont + 1, freq);
        if cont == 0
            waitbar(alpha/0.999, h, 'Processing...');
        end
    
        s.set_alpha_and_mpc_cached(alpha);
    end
    close(h);

end