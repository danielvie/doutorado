
function z_test_final()
    s = Simulation(Enums.SimName.PATINO_1);
    
    % Force match with original standalone script discretization (T=0.1s cumulative)
    s.m_config.Ts = [0, 0.05, 0.10]; 
    s.m_config.c_time = [0.05, 0.04]; % Results in c = [0; -0.01] approx
    
    mpc = Interface.config_mpc();
    mpc.Q = 2; 
    s.set_mpc(mpc);
    
    % Run projection centered at the original point
    s.project_feasibility_region([1, 2, 4], [-0.5; -1.0]);
    disp('Comparison test executed with T=0.1s.');
end
