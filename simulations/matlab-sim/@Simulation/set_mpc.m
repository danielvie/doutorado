function set_mpc(self, options)
    % Build the cycle model, MPC problem, and runtime controller.

    if nargin < 2
        warning('Simulation:set_mpc:DefaultOptions', ...
            ['set_mpc() called without Options.Mpc. Using Options.Mpc(). ', ...
             'For explicit configuration, pass an Options.Mpc instance.']);
        options = Options.Mpc();
    end
    if ~isa(options, 'Options.Mpc')
        error('set_mpc expects an Options.Mpc instance.');
    end
    if ~isempty(options.x_target)
        error('Simulation:set_mpc:CustomTargetUnsupported', ...
            ['Options.Mpc.x_target is incompatible with the orbit-deviation ', ...
             'model. Configure the nominal orbit instead.']);
    end
    if isempty(self.m_config.orbit_anchor)
        error('Simulation:set_mpc:MissingOrbitAnchor', ...
            'Configure the nominal orbit before building the MPC problem.');
    end

    cycle_model = build_cycle_model(self.m_config, options.linearization_method);
    state_count = size(cycle_model.Phi, 1);
    if numel(cycle_model.orbit_anchor) ~= state_count
        error('Orbit anchor must have %d elements.', state_count);
    end

    problem = Mpc.build_problem(cycle_model, self.m_config, options);
    controller = Controllers.MpcController(problem);

    self.m_config.mpc = problem;
    self.m_config.control.on = true;
    self.m_config.control.x_target = cycle_model.orbit_anchor;
    self.set_controller(controller);
end

function model = build_cycle_model(config, method)
    if method == Enums.LinearizationMethod.SWITCHING_TIME
        model = Dynamics.linearize_cycle(config);
        return;
    end
    if method == Enums.LinearizationMethod.AUGMENTED_DURATION
        model = Dynamics.linearize_cycle_augmented(config);
        return;
    end
    error('Unsupported MPC linearization method.');
end
