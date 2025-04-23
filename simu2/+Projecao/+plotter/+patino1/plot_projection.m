function plot_projection(f, v1, v2, v4, xbar)

    clf;

    c1 = [1, 1, 1] * 0.7;
    c2 = [1, 1, 1] * 0.4;
    c4 = [1, 1, 1] * 0.2;

    plot(v4.D, 'color', c4);
    hold on;
    plot(v2.D, 'color', c2);
    plot(v1.D, 'color', c1);
    disp('xbar:');
    disp(xbar)
    plot(xbar(1),xbar(2), 'rx', 'markers', 12, 'linew', 2);
    hold off;

    % labels
    legend("N_p = 4", "N_p = 2", "N_p = 1");

    title('Buck-Boost Feasibility Region')
    xlabel('x_1: Voltage capacitor C');
    ylabel('x_2: Current inductor L');

    % ajustar tamanho da fonte
    ax = gca(f);
    set(ax,'fontsize', 15);
    zoom(f, 0.8);
end
