function plot_xi_helper(t, x, tit, x_la, y_la)
    plot(t, x);

    grid on;
    title(tit);
    xlabel(x_la);
    ylabel(y_la);

    set(gca,'fontsize', 15);
end
