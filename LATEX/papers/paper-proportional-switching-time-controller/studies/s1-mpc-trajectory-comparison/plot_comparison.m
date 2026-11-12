function plot_comparison()
%PLOT_COMPARISON Isolated adaptation of paper.plot_trajectories Figure 3.
here = fileparts(mfilename('fullpath')); root = fileparts(fileparts(here));
addpath(fullfile(root,'scripts')); check_study();
s = load(fullfile(here,'evidence.mat')); e = s.evidence; b = e.benchmark;
p = e.publication; proposed = e.responses{1}; mpc = e.responses{2};
blue = [0,0.35,0.70]; green = [0.0,0.50,0.30]; red = [0.75,0.20,0.15];
fig = paper.publication_figure(12.5); fig.Position(3) = 26.6;
cleanup = onCleanup(@() close(fig));
ax = axes(fig,'Position',[0.065,0.24,0.40,0.68]); hold(ax,'on');
x = p.state_off;
hopen = plot3(ax,x(:,1),x(:,2),x(:,3),'--','Color',red,'LineWidth',0.65);
x = proposed.dense;
hproposed = plot3(ax,x(:,1),x(:,2),x(:,3),'-','Color',blue,'LineWidth',1.0);
x = mpc.dense;
hmpc = plot3(ax,x(:,1),x(:,2),x(:,3),'-.','Color',green,'LineWidth',1.1);
x = p.reference_state;
href = plot3(ax,x(:,1),x(:,2),x(:,3),'-k','LineWidth',1.5);
x = b.initial_state;
hstart = plot3(ax,x(1),x(2),x(3),'ko','MarkerFaceColor','k','MarkerSize',4);
x = b.orbit_anchor;
hanchor = plot3(ax,x(1),x(2),x(3),'kp','MarkerFaceColor',[1,0.8,0],'MarkerSize',7);
% All physical samples, including MPC excursions, determine the 3D limits.
all_states = [proposed.dense;mpc.dense;p.state_off;p.reference_state];
lo = min(all_states,[],1); hi = max(all_states,[],1); pad = 0.06*(hi-lo);
xlim(ax,[lo(1)-pad(1),hi(1)+pad(1)]); ylim(ax,[lo(2)-pad(2),hi(2)+pad(2)]);
zlim(ax,[lo(3)-pad(3),hi(3)+pad(3)]);
xlabel(ax,'$v_{C_1}$ (V)','Interpreter','latex');
ylabel(ax,'$v_{C_2}$ (V)','Interpreter','latex'); zlabel(ax,'$i_L$ (A)','Interpreter','latex');
set(ax,'SortMethod','childorder','GridAlpha',0.12); grid(ax,'on'); view(ax,42,24);
title(ax,'(a) First 100 cycles');
leg = legend(ax,[hproposed,hmpc,hopen,href,hstart,hanchor], ...
    {'Proposed controller','MPC-5','Open loop','Reference','Initial state','Cycle anchor'}, ...
    'NumColumns',3,'Box','off');
set(leg,'Units','normalized','Position',[0.15,0.018,0.70,0.10]);
ax = axes(fig,'Position',[0.61,0.24,0.36,0.68],'XScale','log','YScale','log'); hold(ax,'on');
ybounds = [1e-8,3];
patch(ax,[1,100,100,1],[ybounds(1),ybounds(1),ybounds(2),ybounds(2)], ...
    [0.92,0.94,0.97],'EdgeColor','none');
open_error = p.long_open_loop_error(:); last = numel(open_error)-1;
plot(ax,(1:last)',open_error(2:end),'--','Color',red);
% Actual samples only, each controller ends at k=100. No flooring/resampling.
plot(ax,(1:100)',proposed.error(2:end),'-','Color',blue);
plot(ax,(1:100)',mpc.error(2:end),'-.','Color',green);
yline(ax,0.01,':k');
kp = find(proposed.error<0.01,1)-1; km = find(mpc.error<0.01,1)-1;
ko = find(open_error>=0.01,1,'last');
plot(ax,kp,proposed.error(kp+1),'o','Color',blue,'MarkerFaceColor',blue,'MarkerSize',5);
plot(ax,km,mpc.error(km+1),'d','Color',green,'MarkerFaceColor',green,'MarkerSize',5);
plot(ax,ko,open_error(ko+1),'o','Color',red,'MarkerFaceColor',red,'MarkerSize',5);
text(ax,2,1.4,'Panel (a)','FontSize',9);
text(ax,150,0.018,'$E_k=0.01$','FontSize',9,'Interpreter','latex');
text(ax,18,7e-4,sprintf('Proposed controller\nk = %d',kp),'Color',blue,'VerticalAlignment','top');
text(ax,1.5,8e-6,sprintf('MPC-5\nk = %d',km),'Color',green,'VerticalAlignment','top');
plot(ax,[ko,ko],[1.5e-3,open_error(ko+1)],':','Color',red);
text(ax,ko/1.3,1.2e-3,sprintf('Open loop\nk = %d',ko),'Color',red, ...
    'HorizontalAlignment','right','VerticalAlignment','top');
xlim(ax,[1,last]); ylim(ax,ybounds); xticks(ax,10.^(0:5)); yticks(ax,10.^(-8:2:0));
xlabel(ax,'Cycle k (log scale)'); ylabel(ax,'Cycle-start error $E_k$','Interpreter','latex');
set(ax,'Layer','top','XMinorGrid','off','YMinorGrid','off','GridAlpha',0.12);
grid(ax,'on'); title(ax,'(b) Long-horizon error');
paper.export_publication_figure(fig,fullfile(here,'trajectory-comparison.pdf'));
exportgraphics(fig,fullfile(here,'trajectory-comparison.png'),'Resolution',180);
end
