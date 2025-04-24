function set_mpc_with_np(self, Np)
    % set_mpc - Configures the Model Predictive Control (MPC) parameters for the simulation.
    %
    % This function initializes the MPC optimization problem by computing the necessary
    % matrices and constraints based on the system dynamics and switching constraints.
    % It stores the resulting MPC configuration in the simulation object's configuration.
    %
    % Inputs:
    %   self - Instance of the Simulation class.
    %   Np   - Prediction horizon
    %
    % Outputs:
    %   None. The function modifies the simulation object's configuration in place.
    
    self.set_mpc(Np)
end