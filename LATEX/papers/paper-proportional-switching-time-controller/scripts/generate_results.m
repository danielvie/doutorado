% Reproduce the current article's numerical evidence.
% Run from the paper root: task results
% paper.run_pipeline executes these named stages in order:
%   benchmark -> validate_model -> design_feedback -> simulate_responses
%   -> generate_feasible_regions -> collect_metrics / write_outputs / export_figures
% Each stage receives and returns explicit structs. See scripts/README.md.
% The latest Julia Lyapunov study is separate: studies/lyapunov/analysis.jl.

addpath(fileparts(mfilename('fullpath')));
paper.run_pipeline();
