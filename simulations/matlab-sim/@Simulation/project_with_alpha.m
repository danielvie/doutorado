function project_with_alpha(self, alpha, folder, flag_save)
    % project_with_alpha - Project the feasibility region with a given alpha value.
    %
    % Syntax: project_with_alpha(self, alpha)
    %
    % Inputs:
    %   self - Instance of the Simulation class.
    %   alpha - Alpha value for the simulation.
    %
    % Outputs:
    %   None. The function modifies the simulation object in place.
    
    if nargin < 3
        flag_save = false;
    end
    
    if nargin < 4
        flag_save = false;
    end

    self.set_traj_phase_with_alpha(alpha);
    fig = self.project_feasibility_region();

    name_alpha = sprintf('alpha_%02d', round(alpha*10));
    name_sim = string(self.m_config.sim_name);
    
    % escaping `_`
    name_sim_esc = strrep(name_sim, '_', '\_');
    name_alpha_esc = strrep(name_alpha, '_', '\_');

    title(sprintf('%s (%s)', name_sim_esc, name_alpha_esc));
    
    % saving .fig and vars results as file in `transf/projection` with prefix `alpha_xx_...`
    if flag_save
        vars = Utils.getAllVars();
        name_fig = sprintf('alpha_%s.fig', name_alpha);
        name_vars = sprintf('alpha_%s_vars.mat', name_alpha);
    
        savefig(fig, fullfile(folder, name_fig));
        save(fullfile(folder, name_vars), 'vars');
    end
end