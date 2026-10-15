function plot_conditioned_response(output,response,benchmark,comparison)
%PLOT_CONDITIONED_RESPONSE Align saved 1x error, conditioning, and dwell evidence.
assert(max(abs(comparison.error(:,1)-response.conditioned_error)) < 1e-12);
fig = paper.publication_figure(11);
cleanup = onCleanup(@() close(fig));
blue = [0,0.35,0.70]; red = [0.75,0.20,0.15]; green = [0.15,0.50,0.25];
cycles = 0:numel(response.conditioned_error)-1;
action_cycles = 0:numel(response.conditioning_beta)-1;
last = min(12,action_cycles(end)); period_ms = benchmark.period*1e3;
time = cycles*period_ms; action_time = action_cycles*period_ms;
beta = response.conditioning_beta(:)';
active = action_time(beta<1 & action_cycles<last);

ax(1) = axes(fig,'Position',[0.12,0.65,0.85,0.28],'YScale','log');
hold(ax(1),'on'); shade_active(ax(1),active,period_ms,[1e-5,2]);
closed = semilogy(ax(1),time,response.conditioned_error,'-','Color',blue);
open = semilogy(ax(1),time,response.open_loop_error,'--','Color',red);
mpc = semilogy(ax(1),time,comparison.error(:,2),'-.','Color',green);
yline(ax(1),0.01,':k','$E_k=0.01$','FontSize',9, ...
    'LabelHorizontalAlignment','right','Interpreter','latex');
for j = 1:2
    k = comparison.threshold_cycle(j); color = blue;
    if j==2, color = green; end
    plot(ax(1),k*period_ms,comparison.error(k+1,j),'o', ...
        'MarkerSize',4,'MarkerFaceColor',color,'Color',color);
end
ylim(ax(1),[1e-5,2]); yticks(ax(1),10.^(-5:0));
ylabel(ax(1),'$E_k$','Interpreter','latex');
title(ax(1),'(a) Cycle-start error');
legend(ax(1),[closed,open,mpc],{'Conditioned feedback','Open loop','MPC-5'}, ...
    'Location','southwest','NumColumns',3,'Box','off');

ax(2) = axes(fig,'Position',[0.12,0.43,0.85,0.10]);
hold(ax(2),'on'); shade_active(ax(2),active,period_ms,[0,1.15]);
stairs(ax(2),action_time,beta,'Color',blue);
ylim(ax(2),[0,1.15]); yticks(ax(2),[0,1]);
ylabel(ax(2),'$\beta_k$','Interpreter','latex');
title(ax(2),'(b) Fraction of the proposed timing request applied');
text(ax(2),0.98,0.35,'Shading: scaling active','Units','normalized', ...
    'HorizontalAlignment','right');

ax(3) = axes(fig,'Position',[0.12,0.10,0.85,0.21]); hold(ax(3),'on');
bound = benchmark.applied_schedule_dwell_bound*1e6;
raw = min(response.raw_dwell,[],1)*1e6;
applied = min(response.applied_dwell,[],1)*1e6;
shown = action_cycles<=last;
low = 10*floor(min([raw(shown),0])/10);
high = 10*ceil(max([applied(shown),bound])/10);
patch(ax(3),[0,last,last,0]*period_ms,[low,low,bound,bound],[0.98,0.92,0.91], ...
    'EdgeColor','none','HandleVisibility','off');
requested = plot(ax(3),action_time,raw,'--','Color',red);
executed = plot(ax(3),action_time,applied,'-','Color',blue);
predictive = plot(ax(3),action_time,min(comparison.mpc_dwell,[],1)*1e6, ...
    '-.','Color',green);
yline(ax(3),bound,':k',sprintf('$%g\\,\\mu$s minimum',bound), ...
    'FontSize',9,'Interpreter','latex','LabelHorizontalAlignment','right');
text(ax(3),last*period_ms*0.98,low+0.14*(high-low),'Forbidden dwell', ...
    'HorizontalAlignment','right','Color',red);
ylim(ax(3),[low,high]); ylabel(ax(3),'Minimum dwell (\mus)');
title(ax(3),'(c) Requested and applied schedule');
legend(ax(3),[requested,executed,predictive], ...
    {'Proposed raw','Proposed applied','MPC-5 applied'}, ...
    'Location','southwest','NumColumns',3,'Box','off');
xlabel(ax(3),'Elapsed time (ms)');
for a = ax
    xlim(a,[0,last*period_ms]); xticks(a,0:0.5:last*period_ms);
    grid(a,'on');
    set(a,'Layer','top','XMinorGrid','off','YMinorGrid','off','GridAlpha',0.12);
end
linkaxes(ax,'x');
paper.export_publication_figure(fig,fullfile(output,'conditioned_control_response.pdf'));
end

function shade_active(ax,times,period,limits)
for t = times(:)'
    patch(ax,[t,t+period,t+period,t],[limits(1),limits(1),limits(2),limits(2)], ...
        [0.98,0.93,0.80],'EdgeColor','none','HandleVisibility','off');
end
end
