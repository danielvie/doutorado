
function plot_traj(y, y_off, x0, tit, x_label, y_label)

    plot(y_off(:,1), y_off(:,2), 'linew', 1.2);
    hold on;
    plot(y(:,1), y(:,2), 'linew', 1.2);

    % plot marcadores
    plot(y(1,1), y(1,2), 'ro', 'markers', 10, 'linew', 1.2);
    plot(y(end,1), y(end,2), 'k.', 'markers', 30);
    plot(x0(1), x0(2), 'rx', 'linew', 2, 'markers', 16);

    legend('trajectory', 'start', 'end', 'target x_0', 'location', 'southeast');

    hold off;
    grid on;
    axis equal;
    title(tit);
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);
    legend('mpc off', 'mpc on')
end
