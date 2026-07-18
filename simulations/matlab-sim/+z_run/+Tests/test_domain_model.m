function test_domain_model()
    simulation = Simulation(Enums.SimName.PATINO_1);
    orbit_anchor = simulation.m_config.orbit_anchor;
    [Phi, Gamma] = simulation.get_phi_gamma();

    disturbance = [0.2; -0.1];
    simulation.set_offset(disturbance);
    assert(isequal(simulation.m_config.orbit_anchor, orbit_anchor));
    assert(isequal(simulation.m_config.x0, orbit_anchor + disturbance));

    [Phi_after_disturbance, Gamma_after_disturbance] = ...
        simulation.get_phi_gamma();
    assert(norm(Phi_after_disturbance - Phi) < 1e-12);
    assert(norm(Gamma_after_disturbance - Gamma) < 1e-12);

    options = Options.Mpc();
    options.Np = 2;
    options.Nd = 2;
    simulation.set_mpc(options);
    assert(isequal(simulation.get_target(), orbit_anchor));

    [A_block, B_block] = Mpc.build_blocked_model(Phi, Gamma, 2);
    assert(norm(A_block - Phi^2) < 1e-12);
    assert(norm(B_block - (eye(size(Phi)) + Phi) * Gamma) < 1e-12);
end
