function tests = test_publication_figures
% Presentation uses saved samples, with no changes to the numerical pipeline.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.original_path = path;
addpath(fullfile(root,'scripts'));
p = paper.paths(); addpath(p.simulation);
testCase.TestData.benchmark = paper.benchmark();
s = load(fullfile(p.results,'publication_trajectories.mat'),'trajectories');
testCase.TestData.data = s.trajectories;
end

function teardownOnce(testCase)
path(testCase.TestData.original_path);
end

function testExactWaveformWindow(testCase)
b = testCase.TestData.benchmark; d = testCase.TestData.data;
v = paper.state_history_data(d,b);
n = size(d.reference_state,1)-1;
verifyEqual(testCase,v.cycles,12);
verifyEqual(testCase,v.state_on,d.state_on(1:12*n+1,:));
verifyEqual(testCase,v.state_off,d.state_off(1:12*n+1,:));
verifyEqual(testCase,v.time_on,d.time_on(1:12*n+1));
verifyEqual(testCase,v.time_off,d.time_off(1:12*n+1));
verifyGreaterThan(testCase,max(abs(v.time_on-v.time_off)),1e-6);
verifyEqual(testCase,v.reference_time([1,end]),[0;12*b.period],'AbsTol',1e-14);
for k = 0:11
    rows = k*n+(1:n);
    verifyEqual(testCase,v.reference_state(rows,:),d.reference_state(1:n,:));
    verifyEqual(testCase,v.reference_time(rows),d.reference_time(1:n)+k*b.period,'AbsTol',1e-14);
end
verifyEqual(testCase,v.reference_state(end,:),d.reference_state(end,:));
verifyGreaterThan(testCase,range(v.reference_state),[0,0,0]);
end

function testRejectInvalidOrStaleWaveforms(testCase)
b = testCase.TestData.benchmark; d = testCase.TestData.data;
verifyError(testCase,@() paper.state_history_data(d,b,0),'');
verifyError(testCase,@() paper.state_history_data(d,b,b.cycle_count+1),'');
d.reference_time(end) = b.period*2;
verifyError(testCase,@() paper.state_history_data(d,b),'');
d = testCase.TestData.data; d.time_on(10) = d.time_on(9);
verifyError(testCase,@() paper.state_history_data(d,b),'');
end

function testPrintedSizeContract(testCase)
fig = paper.publication_figure(12);
cleanup = onCleanup(@() close(fig));
verifyEqual(testCase,fig.Position(3:4),[16,12],'AbsTol',0.1);
ax = axes(fig);
verifyEqual(testCase,ax.FontSize,9);
verifyEqual(testCase,ax.LabelFontSizeMultiplier,10/9);
verifyEqual(testCase,get(fig,'DefaultLegendFontSize'),9);
plot(ax,0:2,0:2); xlabel(ax,'Time');
leg = legend(ax,'Test');
output = tempname; mkdir(output);
cleanup_output = onCleanup(@() rmdir(output,'s'));
paper.export_publication_figure(fig,fullfile(output,'type.pdf'));
verifyEqual(testCase,ax.FontSize,9);
verifyEqual(testCase,ax.XLabel.FontSize,10);
verifyEqual(testCase,leg.FontSize,9);
verifyEqual(testCase,fig.PaperSize,[16,12],'AbsTol',0.1);
end

function testReplotOnlyExportsFigures(testCase)
output = tempname; mkdir(output);
cleanup = onCleanup(@() rmdir(output,'s'));
figures_before = findall(groot,'Type','figure');
paper.replot_figures(output);
verifyEqual(testCase,findall(groot,'Type','figure'),figures_before);
for name = {'timing_coordinates','dwell_coupling','inadmissible_request', ...
        'trajectory_comparison','conditioned_control_response','state_time_comparison'}
    verifyTrue(testCase,isfile(fullfile(output,'latex','figures',[name{1},'.pdf'])));
end
verifyEmpty(testCase,dir(fullfile(output,'results','*.csv')));
verifyEmpty(testCase,dir(fullfile(output,'results','*.mat')));
verifyFalse(testCase,isfile(fullfile(output,'latex','metrics.tex')));
end
