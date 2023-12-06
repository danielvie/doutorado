function h = plot_u(yout, varargin)
    u  = fun.get(yout, 'u');
    
    hold on;
    h = plot(u.time, u.data, varargin{:});
    hold off;
    grid on;    
end