function tests = test_paper
% Fast numerical checks. No figure generation or publication files are written.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.original_path = path;
addpath(fullfile(root, 'scripts'));
paths = paper.paths();
addpath(paths.simulation);
benchmark = paper.benchmark();
model = paper.validate_model(benchmark);
testCase.TestData.benchmark = benchmark;
testCase.TestData.model = model;
testCase.TestData.controller = paper.design_feedback(benchmark, model);
saved = load(fullfile(root, 'results', 'paper_results.mat'), 'results');
testCase.TestData.saved = saved.results;
end

function teardownOnce(testCase)
path(testCase.TestData.original_path);
end

function testZeroAction(testCase)
b = testCase.TestData.benchmark;
[applied, beta, dwell] = condition_dwell_times(b.config.Ts, zeros(8, 1), ...
    b.applied_schedule_dwell_bound);
verifyEqual(testCase, applied, zeros(8, 1));
verifyEqual(testCase, beta, 1);
verifyEqual(testCase, dwell, b.nominal_dwell, 'AbsTol', 1e-15);
end

function testFeasibleActionIsUnchanged(testCase)
b = testCase.TestData.benchmark;
raw = ones(8, 1) * 1e-7;
[applied, beta] = condition_dwell_times(b.config.Ts, raw, ...
    b.applied_schedule_dwell_bound);
verifyEqual(testCase, beta, 1);
verifyEqual(testCase, applied, raw);
end

function testMaximalityDirectionAndPeriod(testCase)
b = testCase.TestData.benchmark;
original_rng = rng;
cleanup = onCleanup(@() rng(original_rng));
rng(12);
for index = 1:100
    raw = 1e-3 * randn(8, 1);
    [applied, beta, dwell] = condition_dwell_times(b.config.Ts, raw, ...
        b.applied_schedule_dwell_bound);
    verifyGreaterThan(testCase, beta, 0);
    verifyLessThan(testCase, beta, 1);
    verifyEqual(testCase, applied, beta * raw, 'AbsTol', 1e-15);
    verifyEqual(testCase, sum(dwell), b.period, 'AbsTol', 1e-15);
    verifyGreaterThanOrEqual(testCase, min(dwell), ...
        b.applied_schedule_dwell_bound - 1e-12);
    too_large = min(1, beta + 1e-6);
    invalid_dwell = diff(b.config.Ts(:) + [0; too_large * raw; 0]);
    verifyLessThan(testCase, min(invalid_dwell), b.applied_schedule_dwell_bound);
end
end

function testNominalScheduleMustBeFeasible(testCase)
verifyError(testCase, @() condition_dwell_times([0; 1; 2], 0, 1.1), ...
    '');
end

function testSavedModelAndController(testCase)
m = testCase.TestData.model;
c = testCase.TestData.controller;
s = testCase.TestData.saved;
verifyEqual(testCase, m.Phi, s.linearization.Phi, 'AbsTol', 1e-12);
verifyEqual(testCase, m.Gamma, s.linearization.Gamma, 'RelTol', 1e-10);
verifyEqual(testCase, c.K_aggressive_physical, s.controller.K_aggressive_physical, ...
    'AbsTol', 1e-12);
verifyEqual(testCase, c.K_conservative_physical, s.controller.K_conservative_physical, ...
    'AbsTol', 1e-12);
verifyEqual(testCase, fieldnames(c), fieldnames(s.controller));
verifyGreaterThan(testCase, m.residual_slope, 1.85);
verifyLessThan(testCase, m.residual_slope, 2.15);
end

function testExactPropagationAndAlternateOutputPaths(testCase)
b = testCase.TestData.benchmark;
state = paper.exact_cycle(b.config, b.orbit_anchor, zeros(8, 1));
verifyEqual(testCase, state, b.orbit_anchor, 'AbsTol', 1e-10);
output = tempname;
paths = paper.paths(output);
verifyEqual(testCase, paths.results, fullfile(output, 'results'));
verifyFalse(testCase, isfolder(output));
end
