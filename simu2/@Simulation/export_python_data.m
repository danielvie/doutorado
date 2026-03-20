function export_python_data(self, filename)
    % export_python_data - Export system matrices for Python replication.
    %
    % This method exports Phi, Gamma, c, Q, and R to a .mat file
    % compatible with the python/project_patino2.py script.

    if nargin < 2
        % Default filename based on simulation name
        name_str = lower(string(self.m_config.sim_name));
        name_str = strrep(name_str, 'enums.simname.', '');
        
        % Try to find the project root relative to the Simulation class
        sim_class_path = which('Simulation');
        if ~isempty(sim_class_path)
            project_root = fileparts(fileparts(sim_class_path));
            python_dir = fullfile(project_root, 'python');
        else
            % Fallback to current directory 'python' folder
            python_dir = 'python';
        end
        
        filename = fullfile(python_dir, sprintf('data_%s.mat', name_str));
    end

    fprintf('[*] Exporting simulation data to %s...\n', filename);

    % Get the dynamics
    [Phi, Gamma] = self.get_phi_gamma();
    c = self.get_switching_constraints();

    % Get weights
    Q = self.m_config.Q;
    if isempty(Q)
        Q = eye(size(Phi, 1));
    end

    % Define R as identity (default for these simulations)
    p = size(Gamma, 2);
    R = eye(p);

    % Ensure the directory exists
    [fdir, ~, ~] = fileparts(filename);
    if ~isempty(fdir) && ~exist(fdir, 'dir')
        mkdir(fdir);
    end

    % Save to .mat file
    save(filename, 'Phi', 'Gamma', 'c', 'Q', 'R');

    fprintf('    - Phi: %dx%d\n', size(Phi, 1), size(Phi, 2));
    fprintf('    - Gamma: %dx%d\n', size(Gamma, 1), size(Gamma, 2));
    fprintf('    - c: %d elements\n', numel(c));
    fprintf('[*] Done.\n');

end
