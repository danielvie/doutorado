
function test_patino_params()
    s = Simulation(Enums.SimName.PATINO_1);
    mpc = Interface.config_mpc();
    mpc.Np = 15;
    mpc.Q = diag([10, 10]);
    s.set_mpc(mpc);
    
    try
        fprintf('Starting projection with original Patino1 params...\n');
        s.project_feasibility_region([], s.m_config.x0);
        disp('Projection call finished.');
    catch ME
        fprintf('Error during projection: %s\n', ME.message);
    end
end
