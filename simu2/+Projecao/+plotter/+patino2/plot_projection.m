function plot_projection(f, v1, v2, v3, xbar, varargin)

    clf;

    % colors
    % c1 = [1, 1, 1] * 0.7;
    % c2 = [1, 1, 1] * 0.4;
    % c3 = [1, 1, 1] * 0.2;
    c1 = [0.06, 0.32, 0.69];
    c2 = [0.69, 0.06, 0.32];
    c3 = [0.32, 0.69, 0.06];

    ax = gca(f);

    plot(v3.D, 'color', c3);
    hold on;
    plot(v2.D, 'color', c2);
    plot(v1.D, 'color', c1);
    disp('xbar:');
    disp(xbar)
    plot3(xbar(1),xbar(2),xbar(3), 'rx', 'markers', 12, 'linew', 2);
    hold off;

    alpha(ax, 0.4);

    % labels
    legend(varargin{:});
    title('Multilevel Converter Factibility Region');
    xlabel('x_1: Voltage Capacitor C_1');
    ylabel('x_2: Voltage Capacitor C_2');
    zlabel('x_3: Current Inductor L');


    % ajustar tamanho da fonte
    set(ax,'fontsize', 17);
    % zoom(f, 0.7);
    
end
