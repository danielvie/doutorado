function tests = test_timing_diagrams
% Check schematic numbers and rendering without replacing publication evidence.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.original_path = path;
addpath(fullfile(root, 'scripts'));
paths = paper.paths(); addpath(paths.simulation);
testCase.TestData.benchmark = paper.benchmark();
saved = load(fullfile(paths.results, 'paper_results.mat'), 'results');
testCase.TestData.response = saved.results.response;
end

function teardownOnce(testCase)
path(testCase.TestData.original_path);
end

function testIllustrativeCouplingAndRealRawAction(testCase)
b = testCase.TestData.benchmark; r = testCase.TestData.response;
d = paper.timing_diagram_data(b, r);
verifyEqual(testCase, d.nominal, b.config.Ts(:)*1e6);
verifyEqual(testCase, d.coupling_offsets, [zeros(7, 1); 12]);
verifyEqual(testCase, d.coupling_dwell - d.dwell, [zeros(7, 1); 12; -12], 'AbsTol', 1e-12);
verifyEqual(testCase, d.coupling([1, end]), d.nominal([1, end]));
verifyEqual(testCase, sum(d.coupling_dwell), d.period_us, 'AbsTol', 1e-12);
verifyGreaterThan(testCase, min(d.coupling_dwell), d.dwell_bound_us);
verifyEqual(testCase, d.raw_offsets, r.raw_offsets(:, 1)*1e6);
verifyGreaterThan(testCase, d.raw(9), d.raw(10));
verifyEqual(testCase, d.raw_dwell(9), r.raw_dwell(9, 1)*1e6, 'AbsTol', 1e-10);
verifyEqual(testCase, d.raw_dwell(8), r.raw_dwell(8, 1)*1e6, 'AbsTol', 1e-10);
end

function testStaleResponseIsRejected(testCase)
r = testCase.TestData.response;
r.raw_dwell(9, 1) = r.raw_dwell(9, 1) + 1e-6;
verifyError(testCase, @() paper.timing_diagram_data(testCase.TestData.benchmark, r), '');
end

function testVectorAndPreviewExports(testCase)
output = tempname; mkdir(output);
cleanup = onCleanup(@() rmdir(output, 's'));
paths = paper.paths(output);
figures_before = findall(groot, 'Type', 'figure');
paper.export_timing_diagrams(paths, testCase.TestData.benchmark, testCase.TestData.response);
verifyEqual(testCase, findall(groot, 'Type', 'figure'), figures_before);
for name = {'timing_coordinates', 'dwell_coupling', 'inadmissible_request'}
    verifyTrue(testCase, isfile(fullfile(paths.article_figures, [name{1}, '.pdf'])));
    verifyTrue(testCase, isfile(fullfile(paths.diagnostic_figures, [name{1}, '.png'])));
end
end
