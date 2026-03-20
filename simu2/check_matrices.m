
function check_matrices()
    s = Simulation(Enums.SimName.PATINO_1);
    [Phi, Gamma] = s.get_phi_gamma();
    disp('Phi:'); disp(Phi);
    disp('Gamma:'); disp(Gamma);
    disp('A:'); disp(s.m_config.A{1});
end
