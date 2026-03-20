function plot_projection(f, v1, v2, v3, xbar, varargin)

    clf;

    c1 = [1, 1, 1] * 0.7;
    c2 = [1, 1, 1] * 0.4;
    c3 = [1, 1, 1] * 0.2;

    ax = gca(f);

    plot(v3.D, 'color', c3);
    hold on;
    plot(v2.D, 'color', c2);
    plot(v1.D, 'color', c1);
    disp('xbar:');
    disp(xbar)
    plot(xbar(1), xbar(2), 'rx', 'markers', 12, 'linew', 2);
    hold off;

    % labels
    if ~isempty(varargin)
        % Reverse the labels to match the reversed plotting order (v3, v2, v1)
        legend(varargin{end:-1:1});
    else
        legend("N_p = 4", "N_p = 2", "N_p = 1");
    end

    title('Buck-Boost Feasibility Region')
    xlabel('x_1: Voltage capacitor C');
    ylabel('x_2: Current inductor L');

    % ajustar tamanho da fonte
    set(ax,'fontsize', 15);
    zoom(f, 0.8);
end
