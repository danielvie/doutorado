function plot_invariant_region(output, data)
%PLOT_INVARIANT_REGION Feasible sets for beta 0.25, 0.5, and 1 in four views.
fig = paper.publication_figure(14.5);
cleanup = onCleanup(@() close(fig));
colors = [0.25,0.60,0.30; 0.85,0.40,0.05; 0,0.35,0.70];
fills = [0.94,0.98,0.94; 0.99,0.94,0.87; 0.86,0.93,0.99];
styles = {':','--','-'};
gray = [0.22,0.22,0.22]; gold = [1,0.75,0.15];
e = data.errors;
labels = {'$e_{v_{C_1}}$ (V)','$e_{v_{C_2}}$ (V)','$e_{i_L}$ (A)'};
positions = {[0.09,0.61,0.35,0.31], [0.61,0.61,0.35,0.31], ...
    [0.09,0.18,0.35,0.31], [0.61,0.18,0.35,0.31]};
% Reuse each coordinate's physical limits in every panel where it appears.
points = [vertcat(data.region_vertices{:}); e];
limits = [min(points,[],1); max(points,[],1)];
padding = 0.10*diff(limits,1,1);
limits = limits + [-padding; padding];

ax = axes(fig,'Position',positions{1}); hold(ax,'on');
region_handles = gobjects(1,numel(data.betas));
face_alphas = [0.10,0.18,0.30];
for index = 1:numel(data.betas)
    vertices = data.region_vertices{index};
    region_handles(index) = patch(ax,'Vertices',vertices,'Faces',convhulln(vertices), ...
        'FaceColor',colors(index,:),'FaceAlpha',face_alphas(index),'EdgeColor','none');
    edge = wireframe(ax,vertices,colors(index,:),0.7);
    set(edge,'HandleVisibility','off');
end
trajectory = plot3(ax,e(:,1),e(:,2),e(:,3),'-o','Color',gray, ...
    'MarkerSize',3,'MarkerFaceColor','w','LineWidth',1.1);
initial = plot3(ax,e(1,1),e(1,2),e(1,3),'ks','MarkerFaceColor','k','MarkerSize',5);
origin = plot3(ax,0,0,0,'kp','MarkerFaceColor',gold,'MarkerSize',8);
xlabel(ax,labels{1},'Interpreter','latex');
ylabel(ax,labels{2},'Interpreter','latex');
zlabel(ax,labels{3},'Interpreter','latex');
xlim(ax,limits(:,1)'); ylim(ax,limits(:,2)'); zlim(ax,limits(:,3)');
view(ax,42,24); pbaspect(ax,[1,1,1]);
% The slanted second-voltage axis needs fewer labels at printed size.
y_ticks = yticks(ax);
if numel(y_ticks) > 3, yticks(ax,y_ticks(1:2:end)); end
% Depth sorting preserves the order of the translucent nested surfaces.
grid(ax,'on'); set(ax,'GridAlpha',0.10,'Box','on','SortMethod','depth');
title(ax,'(a) Three-dimensional view');

panel_titles = {'(b) Voltage-voltage projection', ...
    '(c) First voltage-current projection','(d) Second voltage-current projection'};
for index = 1:3
    projected_ax = axes(fig,'Position',positions{index+1});
    hold(projected_ax,'on');
    p = data.projections(index); c = p.coordinates;
    for factor = 1:numel(data.betas)
        boundary = p.boundaries{factor};
        fill(projected_ax,boundary(:,1),boundary(:,2),fills(factor,:), ...
            'EdgeColor',colors(factor,:),'LineStyle',styles{factor},'LineWidth',1.0);
    end
    plot(projected_ax,p.errors(:,1),p.errors(:,2),'-o','Color',gray, ...
        'MarkerSize',3,'MarkerFaceColor','w','LineWidth',1.1);
    plot(projected_ax,p.errors(1,1),p.errors(1,2),'ks','MarkerFaceColor','k','MarkerSize',5);
    plot(projected_ax,0,0,'kp','MarkerFaceColor',gold,'MarkerSize',8);
    xlabel(projected_ax,labels{c(1)},'Interpreter','latex');
    ylabel(projected_ax,labels{c(2)},'Interpreter','latex');
    xlim(projected_ax,limits(:,c(1))'); ylim(projected_ax,limits(:,c(2))');
    grid(projected_ax,'on');
    set(projected_ax,'GridAlpha',0.10,'Box','on','Layer','top');
    title(projected_ax,panel_titles{index});
end

% One legend describes the same geometry and sample markers in all four views.
beta_labels = arrayfun(@(beta) sprintf('$\\beta=%.2g$',beta),data.betas,'UniformOutput',false);
leg = legend(ax,[region_handles,trajectory,initial,origin], ...
    [beta_labels,{'Cycle starts','Initial error, $k=0$','Origin'}], ...
    'Interpreter','latex','NumColumns',3,'Box','off');
set(leg,'Units','normalized','Position',[0.10,0.025,0.82,0.08]);
paper.export_publication_figure(fig,fullfile(output,'appendix_raw_action_region.pdf'));
end

function handle = wireframe(ax, vertices, color, width)
% Remove internal triangulation diagonals, leaving only polyhedron edges.
% Scaled coordinates avoid a voltage/current unit imbalance in coplanarity tests.
scaled = vertices ./ range(vertices,1);
faces = convhulln(scaled);
normals = cross(scaled(faces(:,2),:)-scaled(faces(:,1),:), ...
    scaled(faces(:,3),:)-scaled(faces(:,1),:),2);
normals = normals ./ vecnorm(normals,2,2);
edges = sort([faces(:,[1,2]); faces(:,[2,3]); faces(:,[3,1])],2);
face_ids = repmat((1:size(faces,1))',3,1);
[unique_edges,~,groups] = unique(edges,'rows');
keep = false(size(unique_edges,1),1);
for index = 1:numel(keep)
    adjacent = face_ids(groups == index);
    keep(index) = numel(adjacent) ~= 2 || ...
        abs(dot(normals(adjacent(1),:),normals(adjacent(2),:))) < 1-1e-9;
end
edges = unique_edges(keep,:);
x = [vertices(edges(:,1),1),vertices(edges(:,2),1),nan(size(edges,1),1)]';
y = [vertices(edges(:,1),2),vertices(edges(:,2),2),nan(size(edges,1),1)]';
z = [vertices(edges(:,1),3),vertices(edges(:,2),3),nan(size(edges,1),1)]';
handle = plot3(ax,x(:),y(:),z(:),'-','Color',color,'LineWidth',width);
end
