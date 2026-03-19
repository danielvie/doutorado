function set_mpc(self)
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
    %
    % Functionality:
    % - Reads system configuration and dynamics matrices.
    % - Computes MPC optimization matrices and constraints.
    % - Creates an MPC configuration structure and updates the simulation object.
    
    config_mpc = self.m_config_mpc;

    Np = config_mpc.Np; % Default prediction horizon if not provided
    Nd = config_mpc.Nd; % Default repeated controls if not provided
    
    % reading config values
    config = self.m_config;

    [Phi, Gamma] = self.get_phi_gamma();

    N  = numel(config.Omega);
    p  = N - 1;

    % ?? augmented
    if self.m_state_mode == Enums.StateMode.AUGMENTED
        [Aa, Ba] = Mpc.construcao_modelo_aumentado(Phi, Gamma, Nd);
    end

    if ~isempty(config_mpc.Q)
        Q = config_mpc.Q;
    else
        if self.m_state_mode == Enums.StateMode.AUGMENTED
            Q  = eye(size(Aa, 2)); 
        else
            Q  = eye(size(Phi, 2)); 
        end
    end
    
    R  = eye(p);

    % parametros das restricoes de chaveamento
    c = self.get_switching_constraints();

    % c = [
    %     -dtr(1) + t_min;
    %     -dtr(2) + t_min;
    %     -dtr(3) + t_min;
    %     -dtr(4) + t_min;
    %     -dtr(5) + t_min;
    %     -dtr(6) + t_min;
    %     -dtr(7) + t_min;
    %     -dtr(8) + t_min;
    %     -dtr(9) + t_min;
    % ]; % dimensao: Nx1

    % ?? augmented
    if self.m_state_mode == Enums.StateMode.AUGMENTED
        [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,K,~] = ...
        Mpc.matrizes_ss_mpc_dualmode_switching(Aa,Ba,Q,R,Np,c);
    else
        [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,K,~] = ...
        Mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);
    end

    % criando estrutura com dados MPC
    mpc_opt          = struct();
    mpc_opt.on       = true;

    mpc_opt.x_target = config.x0;
    mpc_opt.H        = H;
    mpc_opt.Hf       = Hf;
    mpc_opt.Phi1Np   = Phi1Np;
    mpc_opt.Qbar     = Qbar;
    mpc_opt.Rbar     = Rbar;
    mpc_opt.Lbar     = Lbar;
    mpc_opt.cbar     = cbar;
    mpc_opt.Pf       = Pf;
    mpc_opt.Sf       = Sf;
    mpc_opt.bf       = bf;
    mpc_opt.PhiNp    = PhiNp;
    mpc_opt.K        = K;
    mpc_opt.p        = p;
    
    mpc_opt.options  = optimoptions('quadprog', 'Algorithm', 'active-set');
    % config.mpc          = mpc_opt;
    
    mpc_opt.vars     = rmfield(Utils.getAllVars(), 'mpc_opt');

    % updating config values of object
    self.m_config.mpc = mpc_opt;
end