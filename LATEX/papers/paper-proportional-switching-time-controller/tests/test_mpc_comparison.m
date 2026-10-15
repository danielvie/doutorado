function tests = test_mpc_comparison
% Saved predictive-control data must match the article before publication.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.original_path = path;
addpath(fullfile(root,'scripts'));
p = paper.paths(); addpath(p.simulation);
testCase.TestData.benchmark = paper.benchmark();
s = load(fullfile(p.results,'paper_results.mat'),'results');
testCase.TestData.results = s.results;
s = load(fullfile(p.root,'studies','mpc-comparison','results','error-scale-1x','study.mat'),'study');
testCase.TestData.study = s.study;
testCase.TestData.metrics = readtable(fullfile(p.root,'studies','mpc-comparison', ...
    'results','metrics.csv'),'TextType','string');
end

function teardownOnce(testCase)
path(testCase.TestData.original_path);
end

function testSelectedCaseAndEvaluationCost(testCase)
d = testCase.TestData; c = adopt(d,d.study);
rows = d.metrics.error_scale == 1;
m = d.metrics(rows,:);
verifyEqual(testCase,c.horizon,5);
verifyEqual(testCase,c.cost,[m.sampled_stage_cost(m.method=="daniel"), ...
    m.sampled_stage_cost(m.method=="mpc-5")],'AbsTol',1e-12);
verifyEqual(testCase,c.threshold_cycle,[6,5]);
verifyEqual(testCase,c.error(:,1),d.results.response.conditioned_error);
verifyEqual(testCase,c.time_ms,c.cycle*d.benchmark.period*1e3);
verifyGreaterThanOrEqual(testCase,min(c.mpc_dwell,[],'all'),3e-6-1e-12);
end

function testRejectStaleModelAndGain(testCase)
d = testCase.TestData; s = d.study;
s.model.Phi(1,1) = s.model.Phi(1,1)+1e-4;
verifyError(testCase,@() adopt(d,s),'MATLAB:assertion:failed');
s = d.study; s.controller.K_aggressive_physical(1,1) = 1;
verifyError(testCase,@() adopt(d,s),'MATLAB:assertion:failed');
s = d.study; s.benchmark.config.A{1}(1,1) = 1;
verifyError(testCase,@() adopt(d,s),'');
end

function testRejectWrongHorizonOrWeights(testCase)
d = testCase.TestData; s = d.study;
i = find(string(s.names)=="mpc-5");
s.problems{i}.prediction_horizon = 10;
verifyError(testCase,@() adopt(d,s),'MATLAB:assertion:failed');
s = d.study; s.problems{i}.qp.hessian(1,1) = s.problems{i}.qp.hessian(1,1)+1;
verifyError(testCase,@() adopt(d,s),'MATLAB:assertion:failed');
s = d.study; s.benchmark.aggressive_input_weight = 0.1;
verifyError(testCase,@() adopt(d,s),'');
end

function testRejectIncompleteOrChangedTrajectory(testCase)
d = testCase.TestData; s = d.study;
i = find(string(s.names)=="mpc-5");
s.responses{i}.completed_cycles = 99;
verifyError(testCase,@() adopt(d,s),'MATLAB:assertion:failed');
s = d.study; s.responses{i}.states(1,5) = s.responses{i}.states(1,5)+0.1;
verifyError(testCase,@() adopt(d,s),'MATLAB:assertion:failed');
end

function testPublicationExport(testCase)
d = testCase.TestData; r = d.results;
output = tempname; mkdir(output);
cleanup = onCleanup(@() rmdir(output,'s'));
p = paper.paths(output);
c = paper.export_mpc_comparison(p,d.benchmark,r.linearization,r.controller,r.response);
saved = load(fullfile(p.results,'mpc_comparison.mat'),'comparison');
verifyEqual(testCase,saved.comparison,c);
rows = readtable(fullfile(p.results,'mpc_comparison.csv'));
verifyEqual(testCase,rows.mpc_error,c.error(:,2),'RelTol',1e-14);
verifyEqual(testCase,c.timing_samples,5760);
verifyEqual(testCase,c.timing_states,24);
verifyGreaterThan(testCase,c.timing_median_us(2),c.timing_median_us(1));
verifyTrue(testCase,isfile(fullfile(output,'latex','mpc_metrics.tex')));
end

function c = adopt(d,study)
r = d.results;
c = paper.mpc_comparison_data(study,d.benchmark,r.linearization,r.controller,r.response);
end
