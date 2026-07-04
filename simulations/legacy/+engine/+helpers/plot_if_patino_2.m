function plot_if_patino_2(y_)

    if size(y_, 2) > 2
        figure(4);
        subplot(1,3,1);
        plot(y_(:,1), y_(:,2)); hold on;
        plot(y_(1,1), y_(1,2), 's');
        plot(y_(end,1), y_(end,2), 'o');
    
        axis([-0.5, 1.5, -0.5, 1]);
        title('Tensao C1 vs Tensao C2')
        grid on;
        hold off;
    
        subplot(1,3,2);
        plot(y_(:,1), y_(:,3)); hold on;
        plot(y_(1,1), y_(1,3), 's');
        plot(y_(end,1), y_(end,3), 'o');
    
        axis([-0.5, 1.5, -0.5, 0.5]);
        title('Tensao C1 vs Corrente Il')
        grid on;
        hold off;
    
        subplot(1,3,3);
        plot(y_(:,2), y_(:,3)); hold on;
        plot(y_(1,2), y_(1,3), 's');
        plot(y_(end,2), y_(end,3), 'o');
    
        axis([-0.5, 1.0, -0.3, 0.3]);
        title('Tensao C2 vs Corrente Il')
        grid on;
        hold off;
    
        figure(5);
        plot3(y_(:,1), y_(:,2), y_(:,3), 'k');
        hold on;
        plot3(y_(1,1), y_(1,2), y_(1,3), 'ro');
        plot3(y_(end,1), y_(end,2), y_(end,3), 'ks');
        hold off;
        grid on;
    end
end