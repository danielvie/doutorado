function plot_projection(f, v1, v2, v4, xbar)

    clf;

    c1 = [1, 1, 1] * 0.7;
    c2 = [1, 1, 1] * 0.4;
    c4 = [1, 1, 1] * 0.2;

    % c1 = [0.06, 0.32, 0.69] * 1.3;
    % c2 = [0.06, 0.32, 0.69] * 0.9;
    % c3 = [0.06, 0.32, 0.69] * 0.7;

    plot(v4.D, 'color', c4);
    hold on;
    plot(v2.D, 'color', c2);
    plot(v1.D, 'color', c1);
    disp(xbar)
    plot(xbar(1),xbar(2), 'rx', 'markers', 12, 'linew', 2);
    hold off;

    % labels
    legend("N_p = 4", "N_p = 2", "N_p = 1");


    title('Double Integrator Feasibility Region')
    xlabel('x_1');
    ylabel('x_2');

    % ajustar tamanho da fonte
    ax = gca(f);
    set(ax,'fontsize', 17);
    % zoom(f, 0.7);
    
end
