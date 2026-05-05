function set_mpc(self, options)
    % set_mpc - Build MPC runtime data and install the default MPC controller.
    %
    % Inputs:
    %   options - Optional Options.Mpc setup schema. If omitted, a default
    %             Options.Mpc is used and a warning is printed.

    if nargin < 2
        warning('Simulation:set_mpc:DefaultOptions', ...
            ['set_mpc() called without Options.Mpc. Using Options.Mpc(). ', ...
             'For explicit configuration, use: mpc_options = Options.Mpc(); s.set_mpc(mpc_options);']);
        options = Options.Mpc();
    end

    if ~isa(options, 'Options.Mpc')
        error('set_mpc expects an Options.Mpc instance.');
    end

    config = self.m_config;
    [Phi, Gamma] = self.get_phi_gamma();

    state_len = size(Phi, 1);
    target = resolve_target(config, options, state_len);

    state_mode = options.state_mode;
    if ~(state_mode == Enums.StateMode.ORIGINAL || state_mode == Enums.StateMode.AUGMENTED)
        error('Options.Mpc.state_mode must be Enums.StateMode.ORIGINAL or Enums.StateMode.AUGMENTED.');
    end

    if state_mode == Enums.StateMode.AUGMENTED
        [A_model, B_model] = Mpc.build_augmented_model(Phi, Gamma, options.Nd);
    else
        A_model = Phi;
        B_model = Gamma;
    end

    model_len = size(A_model, 1);
    if ~isempty(options.Q)
        validate_square_matrix(options.Q, model_len, 'Options.Mpc.Q');
        Q = options.Q;
    else
        Q = eye(model_len);
    end

    p = numel(config.Omega) - 1;
    R = eye(p);
    c = self.get_switching_constraints();

    [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,K,~] = ...
        Mpc.ss_mpc_dualmode_matrices(A_model, B_model, Q, R, options.Np, c);

    mpc_opt = struct();
    mpc_opt.Np       = options.Np;
    mpc_opt.Nd       = options.Nd;
    mpc_opt.state_mode = state_mode;
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
    mpc_opt.solver_options = optimoptions('quadprog', ...
        'Algorithm', options.solver_algorithm, ...
        'Display', options.solver_display);

    controller = Controllers.MpcController(mpc_opt, ...
        'Nd', options.Nd, ...
        'StateMode', state_mode);

    self.m_config.mpc = mpc_opt;
    self.m_config.control.on = true;
    self.m_config.control.x_target = target;
    self.m_state_mode = state_mode;
    self.set_controller(controller);
end

function target = resolve_target(config, options, state_len)
    if ~isempty(options.x_target)
        target = options.x_target(:);
    elseif isprop(config, 'xref') && ~isempty(config.xref)
        target = config.xref(:);
    else
        error('set_mpc requires a target. Set Options.Mpc.x_target or define config.xref.');
    end

    if numel(target) ~= state_len
        error('MPC target must have %d elements. Got %d.', state_len, numel(target));
    end
end

function validate_square_matrix(value, expected_size, name)
    if ~ismatrix(value) || any(size(value) ~= [expected_size, expected_size])
        error('%s must be a %dx%d matrix.', name, expected_size, expected_size);
    end
end
