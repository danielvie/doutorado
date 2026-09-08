function results = run_pipeline(output_root)
%RUN_PIPELINE Reproduce the article, including the adopted Julia certificate.
%   paper.run_pipeline() refreshes publication outputs.
%   paper.run_pipeline(tempdir_path) writes an isolated regression run.
if nargin == 0, output_root = []; end
paths = paper.paths(output_root);
original_path = path;
cleanup_path = onCleanup(@() path(original_path));
addpath(paths.simulation);
assert(exist('dlqr', 'file') == 2, 'Control System Toolbox is required.');
assert(exist('Polyhedron', 'class') == 8, 'MPT3 is required.');
for directory = {paths.results, paths.article_figures, paths.diagnostic_figures}
    if ~isfolder(directory{1}), mkdir(directory{1}); end
end

fprintf('[1/6] Load benchmark and experiment settings\n');
benchmark = paper.benchmark();

fprintf('[2/6] Validate the one-cycle model\n');
model = paper.validate_model(benchmark);

fprintf('[3/6] Design aggressive and conservative feedback\n');
controller = paper.design_feedback(benchmark, model);

fprintf('[4/6] Simulate exact nonlinear responses, including the long horizon\n');
[response, summary, long_response] = paper.simulate_responses(benchmark, controller);

fprintf('[5/6] Compute and export dwell-feasible regions\n');
A = benchmark.state_scale \ model.Phi * benchmark.state_scale;
B = benchmark.state_scale \ model.Gamma * benchmark.timing_scale;
region = generate_feasible_regions(struct( ...
    'A_normalized', A, ...
    'A_aggressive', A - B * controller.K_aggressive_normalized, ...
    'nominal_dwell', benchmark.nominal_dwell, ...
    'applied_schedule_dwell_bound', benchmark.applied_schedule_dwell_bound, ...
    'timing_scale', benchmark.timing_scale, ...
    'state_scale', benchmark.state_scale, ...
    'K_aggressive_normalized', controller.K_aggressive_normalized, ...
    'conditioned_states', response.conditioned_states, ...
    'orbit_anchor', benchmark.orbit_anchor, ...
    'figures_dir', paths.article_figures, ...
    'results_dir', paths.results));

fprintf('[6/6] Export metrics, data, and figures\n');
metrics = paper.collect_metrics(benchmark, model, controller, summary, region);
results = paper.write_outputs(paths, benchmark, model, controller, region, response, metrics);
paper.export_figures(paths, benchmark, model, response);
paper.export_timing_diagrams(paths, benchmark, response);
paper.export_lyapunov(paths, benchmark, model, controller);
paper.export_trajectories(paths, benchmark, model, response, long_response);
paper.write_provenance(paths);
paper.print_summary(paths, benchmark, model, summary, region, metrics);
end
