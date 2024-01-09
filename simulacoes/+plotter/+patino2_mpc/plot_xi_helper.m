function plot_xi_helper(t, yi, tit, x_label, y_label)
    plot(t, yi);

    grid on;
    title(tit)
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);

end

