function data = invariant_region_figure_data(region, state_scale, states, anchor)
%INVARIANT_REGION_FIGURE_DATA Fixed-beta feasible sets and saved cycle samples.
% C_beta = C_1 / beta. No simulation, solver, or numerical output writes.
vertices = region.vertices_normalized;
assert(size(vertices,2) == 3 && isequal(size(state_scale),[3,3]), ...
    'The appendix figure requires three states.');
assert(size(states,1) == 3 && isequal(size(anchor),[3,1]), ...
    'Expected physical states in columns and a column cycle anchor.');
assert(all(isfinite([vertices(:); state_scale(:); states(:); anchor(:)])), ...
    'Figure inputs must be finite.');
assert(region.regions_coincide, 'Saved vertices must describe the full raw-action feasible set.');
betas = sort([region.comparison_betas(:)',1]);
assert(isequal(betas,[0.25,0.5,1]), ...
    'Saved region factors are stale; regenerate the comparison for 0.25, 0.5, and 1.');
entry = region.metrics.first_invariant_region_cycle;
assert(isscalar(entry) && entry >= 1 && entry == floor(entry) && entry < size(states,2), ...
    'Expected a saved first-entry cycle after the initial state.');
last = min(max(10,entry+2),size(states,2)-1);
data = struct('vertices',(state_scale*vertices')', 'betas',betas, ...
    'errors',(states(:,1:last+1)-anchor)', 'cycles',(0:last)', ...
    'first_entry_cycle',entry);
for index = 1:numel(betas)
    data.region_vertices{index} = data.vertices/betas(index);
end
% Projection commutes with convex hull. These are projected silhouettes,
% not intersections with a zero-error plane. Entry remains the saved 3D result.
pairs = [1,2; 1,3; 2,3];
for index = 1:size(pairs,1)
    coordinates = pairs(index,:);
    boundaries = cell(size(betas));
    for factor = 1:numel(betas)
        projected = data.region_vertices{factor}(:,coordinates);
        boundary = convhull(projected(:,1),projected(:,2));
        boundaries{factor} = projected(boundary,:);
    end
    data.projections(index) = struct('coordinates',coordinates, ...
        'boundaries',{boundaries}, 'errors',data.errors(:,coordinates));
end
end
