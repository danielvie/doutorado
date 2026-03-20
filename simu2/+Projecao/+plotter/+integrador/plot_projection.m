function plot_projection(f, v1, v2, v3, xbar, varargin)

    clf;

    c1 = [1, 1, 1] * 0.7;
    c2 = [1, 1, 1] * 0.4;
    c3 = [1, 1, 1] * 0.2;

    plot(v3.D, 'color', c3);
    hold on;
    plot(v2.D, 'color', c2);
    plot(v1.D, 'color', c1);
    disp(xbar)
    plot(xbar(1), xbar(2), 'rx', 'markers', 12, 'linew', 2);
    hold off;

    % labels
    if ~isempty(varargin)
        legend(varargin{:});
    else
        legend("N_p = 4", "N_p = 2", "N_p = 1");
    end

    title('Double Integrator Feasibility Region')
    xlabel('x_1');
    ylabel('x_2');

    % ajustar tamanho da fonte
    ax = gca(f);
    set(ax, 'fontsize', 17);
    
end
