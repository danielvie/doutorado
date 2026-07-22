
sim = Enums.SimName.LAB_CIRCUIT;
flag_save = true;

if sim == Enums.SimName.PATINO_2
    folder = fullfile('transf', 'projection_patino2');
elseif sim == Enums.SimName.LAB_CIRCUIT
    folder = fullfile('transf', 'projection_lab_circuit');
end


s = Simulation(sim);
A = 0.1:0.1:0.9;

for a = 1:numel(A)
    ai = A(a);
    s.project_with_alpha(ai, folder, flag_save);
end