function fig = project_feasibility_region(self, horizons)
    % project_feasibility_region - Project the feasibility region of the system.
    % 
    % Note: This function uses the package +Projecao to create the projections.
    % 
    % Syntax: fig = project_feasibility_region(self, horizons, x_eq_in)
    %
    % Inputs:
    %   self     - Instance of the Simulation class.
    %   horizons - (Optional) Array of prediction horizons (e.g., [1, 2, 4]).
    %   x_eq_in  - (Optional) Custom equilibrium state vector to center the projection.
    %
    % Outputs:
    %   fig - Figure handle for the plot.

    if nargin < 2 || isempty(horizons)
        horizons = [1, 2, 4];
    end

    disp('Projecting feasibility region...');
    fprintf('Horizons: [%s]\n', num2str(horizons));

    % Retrieve system matrices (Phi and Gamma) and the equilibrium state
    [Phi, Gamma] = self.get_phi_gamma();
    
    % ...
    
end
