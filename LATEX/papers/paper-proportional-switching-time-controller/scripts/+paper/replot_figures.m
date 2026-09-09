function replot_figures(output_root)
%REPLOT_FIGURES Refresh manuscript numerical graphics from saved evidence only.
% TikZ common-P geometry is compiled by task build. No solvers or propagation.
if nargin == 0, output_root = []; end
source = paper.paths(); paths = paper.paths(output_root);
original_path = path;
cleanup = onCleanup(@() path(original_path));
addpath(source.simulation);
b = paper.benchmark();
saved = load(fullfile(source.results,'paper_results.mat'),'results');
r = saved.results;
assert(isequal(r.schedule.Ts,b.config.Ts) && ...
    isequal(r.schedule.orbit_anchor,b.orbit_anchor), 'Saved schedule differs from benchmark.');
assert(isequal(r.controller.state_scale,b.state_scale), 'Saved state scales differ from benchmark.');
saved = load(fullfile(source.results,'publication_trajectories.mat'),'trajectories');
for directory = {paths.article_figures,paths.diagnostic_figures}
    if ~isfolder(directory{1}), mkdir(directory{1}); end
end
paper.export_timing_diagrams(paths,b,r.response);
paper.plot_conditioned_response(paths.diagnostic_figures,r.response,b);
copyfile(fullfile(paths.diagnostic_figures,'conditioned_control_response.pdf'), ...
    fullfile(paths.article_figures,'conditioned_control_response.pdf'));
paper.plot_trajectories(paths.article_figures,saved.trajectories,b);
region_data = paper.invariant_region_figure_data(r.invariant_raw_action_region, ...
    b.state_scale,r.response.conditioned_states,r.schedule.orbit_anchor);
paper.plot_invariant_region(paths.article_figures,region_data);
fprintf('Replotted manuscript figures from saved data; numerical evidence unchanged.\n');
end
