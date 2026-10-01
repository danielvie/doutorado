function plot_article_response_comparison(b, daniel, relaxed, marcolino, open_loop, output_dir, error_scale)
%PLOT_ARTICLE_RESPONSE_COMPARISON Study-specific remake of the article's Fig. 4.
% The article's original figure is kept unchanged under reference/. A single
% beta does not exist for sequential delays: show delayed-switch count instead.
last = 25;
assert(numel(daniel.error) >= last+1 && numel(marcolino.error) >= last+1);
assert(numel(open_loop.error) == last+1);
cycle = 0:last;
action_cycle = 0:last-1;
nominal = b.config.Ts(:);
raw_daniel = min(diff(nominal + [zeros(1,last); ...
    daniel.raw_offsets(:,1:last); zeros(1,last)], 1), [], 1) * 1e6;
raw_relaxed = min(diff(nominal + [zeros(1,last); ...
    relaxed.raw_offsets(:,1:last); zeros(1,last)], 1), [], 1) * 1e6;
raw_marcolino = min(diff(nominal + [zeros(1,last); ...
    marcolino.raw_offsets(:,1:last); zeros(1,last)], 1), [], 1) * 1e6;
applied_daniel = min(daniel.dwell(:,1:last), [], 1) * 1e6;
applied_relaxed = min(relaxed.dwell(:,1:last), [], 1) * 1e6;
applied_marcolino = min(marcolino.dwell(:,1:last), [], 1) * 1e6;
requested = nominal + [zeros(1,last); marcolino.raw_offsets(:,1:last); zeros(1,last)];
delayed_switches = sum(marcolino.boundaries(2:end,1:last) - ...
    requested(2:end,:) > 1e-12, 1);
assert(all(delayed_switches >= 0 & delayed_switches <= numel(b.config.Omega)));

blue = [0.10 0.37 0.71];
green = [0.15 0.55 0.30];
orange = [0.87 0.35 0.12];
gray = [0.38 0.38 0.38];
f = figure('Visible','off','Position',[70 70 1200 1050]);
t = tiledlayout(f,3,1,'TileSpacing','compact','Padding','compact');
ax = nexttile(t,1);
h_d = semilogy(ax,cycle,max(daniel.error(1:last+1),1e-12), ...
    'Color',blue,'LineWidth',1.8); hold(ax,'on');
h_r = semilogy(ax,cycle,max(relaxed.error(1:last+1),1e-12), ...
    'Color',green,'LineWidth',1.8);
h_rg = semilogy(ax,cycle,max(relaxed.global_phase_error(1:last+1),1e-12), ...
    '--','Color',green,'LineWidth',1.4);
h_m = semilogy(ax,cycle,max(marcolino.error(1:last+1),1e-12), ...
    'Color',orange,'LineWidth',1.8);
h_g = semilogy(ax,cycle,max(marcolino.global_phase_error(1:last+1),1e-12), ...
    '--','Color',orange,'LineWidth',1.4);
h_o = semilogy(ax,cycle,max(open_loop.error,1e-12), ...
    ':','Color',gray,'LineWidth',1.7);
yline(ax,0.01,':k','0.01','HandleVisibility','off');
xlim(ax,[0,last]); ylim(ax,[1e-10,max(2,ceil(max(open_loop.error)))]);
grid(ax,'on'); ylabel(ax,'Normalized cycle-start error');
title(ax,'(a) Moving-anchor error versus fixed-clock tracking error');
legend(ax,[h_d,h_r,h_rg,h_m,h_g,h_o], ...
    {'daniel, anchor = fixed clock','daniel-relaxed, anchor', ...
     'daniel-relaxed, fixed clock','marcolino, anchor', ...
     'marcolino, fixed clock','Open loop'}, ...
    'Location','southwest','NumColumns',2);

ax = nexttile(t,2);
yyaxis(ax,'left');
h_beta = stairs(ax,0:last,[daniel.beta(1:last);daniel.beta(last)], ...
    'Color',blue,'LineWidth',1.6); hold(ax,'on');
h_relaxed_beta = stairs(ax,0:last,[relaxed.beta(1:last);relaxed.beta(last)], ...
    'Color',green,'LineWidth',1.6);
ylim(ax,[0,1.1]); ylabel(ax,'Applied fraction \beta_k');
ax.YColor = blue;
yyaxis(ax,'right');
h_delay = stairs(ax,0:last,[delayed_switches delayed_switches(end)], ...
    'Color',orange,'LineWidth',1.6);
ylim(ax,[0,max(1,max(delayed_switches))+0.4]);
yticks(ax,0:max(1,max(delayed_switches)));
ylabel(ax,'Marcolino: delayed switches per cycle');
ax.YColor = orange;
xlim(ax,[0,last]); grid(ax,'on');
title(ax,'(b) Conditioning activity: distinct quantities, not a shared beta');
legend(ax,[h_beta,h_relaxed_beta,h_delay], ...
    {'daniel: \beta_k','daniel-relaxed: \beta_k','marcolino: delayed switches'}, ...
    'Location','northeast');

ax = nexttile(t,3);
low = 10*floor(min([raw_daniel raw_relaxed raw_marcolino 0])/10);
high = max(30,10*ceil(max([applied_daniel applied_relaxed applied_marcolino 3])/10));
patch(ax,[0,last,last,0],[low,low,3,3],[1,.94,.93], ...
    'EdgeColor','none','HandleVisibility','off'); hold(ax,'on');
h_rd = plot(ax,action_cycle,raw_daniel,'--','Color',blue,'LineWidth',1.2);
h_ad = plot(ax,action_cycle,applied_daniel,'-','Color',blue,'LineWidth',1.7);
h_rr = plot(ax,action_cycle,raw_relaxed,'--','Color',green,'LineWidth',1.2);
h_ar = plot(ax,action_cycle,applied_relaxed,'-','Color',green,'LineWidth',1.7);
h_rm = plot(ax,action_cycle,raw_marcolino,'--','Color',orange,'LineWidth',1.2);
h_am = plot(ax,action_cycle,applied_marcolino,'-','Color',orange,'LineWidth',1.7);
yline(ax,3,':k','3 \mus minimum','HandleVisibility','off');
xlim(ax,[0,last]); ylim(ax,[low,high]); grid(ax,'on');
ylabel(ax,'Minimum dwell (\mus)'); xlabel(ax,'Cycle k');
title(ax,'(c) Minimum requested and executed dwells');
legend(ax,[h_rd,h_ad,h_rr,h_ar,h_rm,h_am], ...
    {'daniel requested','daniel applied', ...
     'daniel-relaxed requested','daniel-relaxed applied', ...
     'marcolino requested','marcolino applied'}, ...
    'Location','southwest','NumColumns',2);
for axis = [t.Children]'
    if isa(axis,'matlab.graphics.axis.Axes')
        xticks(axis,0:5:last);
    end
end
sgtitle(t,sprintf('Three-conditioner early response, initial error scale %g',error_scale));
exportgraphics(f,fullfile(output_dir,'article_response_with_marcolino.pdf'), ...
    'ContentType','vector');
exportgraphics(f,fullfile(output_dir,'article_response_with_marcolino.png'), ...
    'Resolution',180);
close(f);
end
