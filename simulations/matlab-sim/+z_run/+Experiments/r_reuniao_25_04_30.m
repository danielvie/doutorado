simulation = Simulation(Enums.SimName.LAB_CIRCUIT);
simulation.alpha(0.5);

options = Options.Mpc();
options.Nd = 3;
simulation.set_mpc(options);

cycle_model = simulation.get_cycle_linear_model();
prediction = simulation.m_config.mpc.prediction;

Phi = cycle_model.Phi;
Gamma = cycle_model.Gamma;
A_block = prediction.state_transition;
B_block = prediction.input_matrix;

disp('One-cycle state transition:');
disp(Phi);
disp('One-cycle switching-offset map:');
disp(Gamma);
disp('Held-input block state transition:');
disp(A_block);
disp('Held-input block input matrix:');
disp(B_block);
