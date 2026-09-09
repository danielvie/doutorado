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
s = load(fullfile(p.results,'paper_results.mat'),'results');
testCase.TestData.results = s.results;
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

function testInvariantRegionGeometryAndSamples(testCase)
r = testCase.TestData.results; S = r.controller.state_scale;
v = paper.invariant_region_figure_data(r.invariant_raw_action_region, ...
    S,r.response.conditioned_states,r.schedule.orbit_anchor);
verifyEqual(testCase,v.vertices,r.invariant_raw_action_region.vertices_physical,'AbsTol',1e-12);
verifyEqual(testCase,v.betas,[0.25,0.5,1]);
verifyEqual(testCase,v.errors,(r.response.conditioned_states(:,1:11)-r.schedule.orbit_anchor)');
verifyEqual(testCase,v.cycles,(0:10)');
verifyEqual(testCase,v.first_entry_cycle,r.metrics.first_invariant_region_cycle);
% Independent dwell inequalities check 3D membership, not a visual projection.
K = r.controller.K_aggressive_physical;
D = [eye(size(K,1)); zeros(1,size(K,1))]-[zeros(1,size(K,1)); eye(size(K,1))];
H = D*K;
h = diff(r.schedule.Ts(:))-r.metrics.applied_schedule_dwell_bound_us*1e-6;
[~,raw_volume] = convhulln(v.vertices);
for factor = 1:numel(v.betas)
    beta = v.betas(factor); vertices = v.region_vertices{factor};
    verifyEqual(testCase,vertices,v.vertices/beta);
    [~,volume] = convhulln(vertices);
    verifyEqual(testCase,volume/raw_volume,beta^-3,'AbsTol',1e-10);
    verifyLessThanOrEqual(testCase,max(beta*H*vertices'-h,[],'all'),1e-12);
    A_beta = r.linearization.Phi-beta*r.linearization.Gamma*K;
    verifyLessThanOrEqual(testCase,max(beta*H*A_beta*vertices'-h,[],'all'),1e-12);
    verifyLessThan(testCase,max(abs(eig(A_beta))),1);
    if factor < 3
        % Compare scaled raw vertices with the independently computed MPT set.
        saved = r.invariant_raw_action_region.comparison_feasible{factor};
        verifyLessThanOrEqual(testCase,max(saved.A*(S\vertices')-saved.b,[],'all'),1e-9);
        verifyLessThanOrEqual(testCase,max(beta*H*S*saved.V'-h,[],'all'),1e-12);
        verifyTrue(testCase,r.invariant_raw_action_region.comparison_regions_are_invariant(factor));
    end
end
verifyTrue(testCase,all(v.betas(1)*H*v.errors(1,:)' <= h+1e-12));
verifyFalse(testCase,all(v.betas(2)*H*v.errors(1,:)' <= h+1e-12));
inside = all(H*v.errors' <= h+1e-12,1);
verifyEqual(testCase,find(inside,1)-1,v.first_entry_cycle);
verifyFalse(testCase,inside(1));
verifyEqual(testCase,vertcat(v.projections.coordinates),[1,2;1,3;2,3]);
for index = 1:3
    p = v.projections(index); c = p.coordinates;
    verifyEqual(testCase,p.errors,v.errors(:,c));
    for factor = 1:numel(v.betas)
        boundary = p.boundaries{factor}; vertices = v.region_vertices{factor};
        verifyEqual(testCase,boundary(1,:),boundary(end,:));
        verifyTrue(testCase,all(ismember(boundary,vertices(:,c),'rows')));
        verifyTrue(testCase,all(inpolygon(vertices(:,c(1)),vertices(:,c(2)), ...
            boundary(:,1),boundary(:,2))));
        if factor > 1
            outer = p.boundaries{factor-1};
            verifyTrue(testCase,all(inpolygon(boundary(:,1),boundary(:,2),outer(:,1),outer(:,2))));
        end
    end
end
end

function testProjectedMembershipDoesNotSetEntry(testCase)
% In the unit simplex, (0.4,0.4,0.4) is outside in 3D but inside all
% three pairwise projections. Keep the entry from the full-dimensional record.
region = struct('vertices_normalized',[zeros(1,3);eye(3)], ...
    'regions_coincide',true,'comparison_betas',[0.25,0.5], ...
    'metrics',struct('first_invariant_region_cycle',1));
states = [0.4,0.1,0;0.4,0.1,0;0.4,0.1,0];
v = paper.invariant_region_figure_data(region,eye(3),states,zeros(3,1));
verifyGreaterThan(testCase,sum(states(:,1)),1);
verifyEqual(testCase,v.first_entry_cycle,1);
for index = 1:3
    p = v.projections(index); raw_boundary = p.boundaries{end};
    verifyTrue(testCase,inpolygon(p.errors(1,1),p.errors(1,2), ...
        raw_boundary(:,1),raw_boundary(:,2)));
end
end

function testRejectStaleRegionFactors(testCase)
r = testCase.TestData.results; region = r.invariant_raw_action_region;
region.comparison_betas = [0.2,0.5];
verifyError(testCase,@() paper.invariant_region_figure_data(region, ...
    r.controller.state_scale,r.response.conditioned_states,r.schedule.orbit_anchor),'');
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
        'trajectory_comparison','conditioned_control_response','state_time_comparison', ...
        'appendix_raw_action_region'}
    verifyTrue(testCase,isfile(fullfile(output,'latex','figures',[name{1},'.pdf'])));
end
verifyEmpty(testCase,dir(fullfile(output,'results','*.csv')));
verifyEmpty(testCase,dir(fullfile(output,'results','*.mat')));
verifyFalse(testCase,isfile(fullfile(output,'latex','metrics.tex')));
end
