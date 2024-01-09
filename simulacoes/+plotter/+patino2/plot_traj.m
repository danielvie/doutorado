function plot_traj(y, tit, x_la, y_la, z_la)

    vc1_ = y(:,1);
    vc2_ = y(:,2);
    i_l_ = y(:,3);

    plot3(vc1_, vc2_, i_l_, 'k');

    grid on;

    title(tit);
    xlabel(x_la);
    ylabel(y_la);
    zlabel(z_la);

    set(gca,'fontsize', 15);
end
