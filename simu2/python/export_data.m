%% Export Simulation Data to Python
% This script exports the linearized dynamics and constraints for all
% simulation configurations: INTEGRADOR_DUPLO, PATINO_1, PATINO_2, and LAB_CIRCUIT.
% The exported .mat files can be used with the Python feasibility region scripts.

fprintf('[*] Exporting simulation data for Python scripts...\n');

try
    % Add project root to path
    script_dir = fileparts(mfilename('fullpath'));
    project_root = fullfile(script_dir, '..');
    addpath(project_root);

    % Define all simulation types to export
    sim_types = [...
        Enums.SimName.INTEGRADOR_DUPLO, ...
        Enums.SimName.PATINO_1, ...
        Enums.SimName.PATINO_2, ...
        Enums.SimName.LAB_CIRCUIT];

    sim_names = {'integrador_duplo', 'patino_1', 'patino_2', 'lab_circuit'};

    for i = 1:length(sim_types)
        sim_type = sim_types(i);
        sim_name = sim_names{i};

        fprintf('\n[*] Processing %s...\n', upper(sim_name));

        try
            s = Simulation(sim_type);
            s.export_python_data();
            fprintf('    [OK] %s exported successfully.\n', sim_name);
        catch ME
            warning('Failed to export %s: %s', sim_name, ME.message);
            fprintf('    [!] Skipped %s (see warning above).\n', sim_name);
        end
    end

    fprintf('\n[*] Export complete.\n');
    fprintf('You can now run the Python scripts:\n');
    fprintf('    uv run python/project_patino1.py\n');
    fprintf('    uv run python/project_patino2.py\n');
    fprintf('(Add project_patino1.py support by copying and adapting patino2 logic)\n');

catch ME
    warning('Failed to initialize export process.');
    fprintf('[!] Error: %s\n', ME.message);
    fprintf('[TIP] Ensure you are in the project folder or the "python" folder.\n');
end
