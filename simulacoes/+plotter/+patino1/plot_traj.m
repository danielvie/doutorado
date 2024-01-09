
function plot_traj(y, xref, tit, x_label, y_label)
    hold off;
    plot(y(:,1), y(:,2), 'LineWidth', 2); hold on;
    plot(xref(1), xref(2), 'rx');

    axis equal;
    grid on;
    title(tit);
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);
end
