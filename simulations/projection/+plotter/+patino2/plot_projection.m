function plot_projection(f, volumes, xbar)

    clf;

    % colors
    colors = [
        0.06, 0.32, 0.69;
        0.69, 0.06, 0.32;
        0.32, 0.69, 0.06;
        0.69, 0.32, 0.80;
        0.80, 0.60, 0.10
    ];

    ax = gca(f);

    hold on;
    labels = {};
    for i = 1:numel(volumes)
        c = colors(mod(i-1, size(colors,1))+1, :);
        plot(volumes{i}.v.D, 'color', c);
        labels{end+1} = volumes{i}.label;
    end

    disp(xbar)
    if numel(xbar) >= 3
        plot3(xbar(1), xbar(2), xbar(3), 'rx', 'markers', 12, 'linew', 2);
    else
        plot(xbar(1), xbar(2), 'rx', 'markers', 12, 'linew', 2);
    end
    hold off;

    alpha(ax, 0.4);

    % labels
    legend(labels{:});
    title('Multilevel Converter Factibility Region');
    xlabel('x_1: Voltage Capacitor C_1');
    ylabel('x_2: Voltage Capacitor C_2');
    zlabel('x_3: Current Inductor L');


    % ajustar tamanho da fonte
    set(ax,'fontsize', 17);
    % zoom(f, 0.7);
    
end
