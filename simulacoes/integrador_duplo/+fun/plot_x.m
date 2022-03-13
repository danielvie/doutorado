function plot_x(yout, varargin)
    x  = fun.get(yout, 'x');
    
    hold on;
    plot(x.data(:,1), x.data(:,2), varargin{:});
    hold off;
    grid on;    
end