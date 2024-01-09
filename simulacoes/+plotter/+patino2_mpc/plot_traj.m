function plot_traj(y, y_off, x0, tit, x_label, y_label, z_label)

    yo1 = y_off(:,1);
    yo2 = y_off(:,2);
    yo3 = y_off(:,3);

    y1 = y(:,1);
    y2 = y(:,2);
    y3 = y(:,3);

    plot3(yo1, yo2, yo3);
    hold on;
    plot3(y1, y2, y3);

    % plot marcadores
    plot3(y1(1), y2(1), y3(1), 'ro', 'markers', 15, 'linew', 2); % start point
    plot3(yo1(end), yo2(end), yo3(end), 'k*', 'markers', 15, 'linew', 2); % end point
    plot3(y1(end), y2(end), y3(end), 'k.', 'markers', 50); % end point
    plot3(x0(1), x0(2), x0(3), 'rx', 'markers', 25, 'linew', 3); % target x_0

    legend('trajectory MPC off', 'trajectory MPC on', 'start', 'end MPC off', 'end MPC on', 'target x_0', 'location', 'southeast');

    hold off;
    grid on;
    title(tit)
    xlabel(x_label);
    ylabel(y_label);
    zlabel(z_label);
    set(gca,'fontsize', 15);

end

