function plot_u_signal(t_off, m_off, t, m, tit, x_label, y_label)
    f = stairs(t_off, m_off, 'linew', 2);
    hold on;
    stairs(t, m, 'linew', 2, 'linestyle', '--');
    hold off;
    
    grid on;
    title(tit);
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);
    legend('modes target trajectory', 'modes simulation');

    % removing the values that are not integers in Y axis
    v = f.Parent.YTick;
    
    % indices for integer
    p = abs(v - floor(v)) < 0.1;
    
    % update yticks
    f.Parent.YTick = v(p);

end