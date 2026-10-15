function problem = mpc_problem(b, model, horizon)
%MPC_PROBLEM Reuse the simulation QP with the article's units and weights.
normalized_model = struct( ...
    'Phi', b.state_scale \ model.Phi * b.state_scale, ...
    'Gamma', b.state_scale \ model.Gamma * b.timing_scale);
% This config is only read by the QP's dwell-bound builder, not propagation.
config = b.config;
config.Ts = config.Ts / b.timing_scale;
config.c_time = b.applied_schedule_dwell_bound / b.timing_scale;
options = Options.Mpc();
options.Np = horizon;
options.Nd = 1;
options.state_mode = Enums.StateMode.ORIGINAL;
options.linearization_method = Enums.LinearizationMethod.SWITCHING_TIME;
% build_problem fixes R=I. Multiplying the whole article cost by 1/r
% gives Q=I/r, R=I without changing its optimizer or terminal LQR gain.
options.Q = eye(size(model.Phi, 1)) / b.aggressive_input_weight;
problem = Mpc.build_problem(normalized_model, config, options);
end
