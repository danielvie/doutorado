classdef ResPatino1_matriz
    properties
        data
    end

    methods
        function self = ResPatino1_matriz(data)
            self.data = data;
        end

        function plot_traj(self)
            y = self.data.y;
            xref = self.data.c.xref;
            tit = "Buck-Boost Converter: Cyclic Trajectory";
            x_label = "x_1 - Voltage Capacitor C";
            y_label = "x_2 - Current Inductor L";
            
            y_ = self.data.y_;
            Y = self.data.Y;

            hold off;
            plot(y_(:,1), y_(:,2), 'LineWidth', 2); hold on;
            
            for i = 1:numel(Y)
                yi = Y{i};
                plot(yi(:,1), yi(:,2), 'LineWidth', 2); 
            end

            plot(xref(1), xref(2), 'rx', 'linew', 2, 'markers', 10);


            % plotar erro propagado
            x0 = self.data.config.x0;
            E  = self.data.E;
            
            for i = 1:numel(E)
                xx = x0 + E{i};
                plot(xx(1), xx(2), 'bx', 'markers', 12, 'linew', 2);
            end


            axis equal;
            grid on;
            title(tit);
            xlabel(x_label);
            ylabel(y_label);
            set(gca,'fontsize', 15);
        end

        function plot_u_signal(self)

            t = self.data.t;
            m = self.data.m;
            tit = "Buck-Booooost Converter Signal Command";
            x_label = "t - time (s)";
            y_label = "u - switch command";
            
            t_ = self.data.t_;
            m_ = self.data.m_;

            hold off;

            f = stairs(t, m, 'linew', 3); hold on;
            stairs(t_, m_, 'linew', 3);

            grid on;
            title(tit)
            xlabel(x_label);
            ylabel(y_label);
            set(gca,'fontsize', 15);

            % removing the values that are not integers in Y axis
            v = f.Parent.YTick;
            
            % indices for integer
            p = abs(v - floor(v)) < 0.1;
            
            % update yticks
            f.Parent.YTick = v(p);
            
            xlim([t(1), t(end)]);
        end
        
        function f = plot(self)
            f = {};

            f{2} = figure(2);
            self.plot_u_signal();

            f{1} = figure(1);
            self.plot_traj();
            
        end

    end
end