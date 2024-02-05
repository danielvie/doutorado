function plot_u_signal(t, m, tit, x_label, y_label)

    hold off;

    f = stairs(t, m, 'linew', 3); 

    hold on;
    grid on;
    title(tit)
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);

    % removing the values that are not integers in Y axis
    v = f.Parent.YTick;
    
    % indices for integer
    p = abs(v - floor(v)) < 0.1;
    
    % update yticks
    f.Parent.YTick = v(p);
    
    xlim([t(1), t(end)]);
end
