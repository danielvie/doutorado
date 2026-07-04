classdef ResPatino1
    properties
        data
    end

    methods
        function self = ResPatino1(data)
            self.data = data;
        end

        function plot_traj(self)
            
            y = self.data.y;
            xref = self.data.c.xref;
            tit = "Buck-Boost Converter: Cyclic Trajectory";
            x_label = "x_1 - Voltage Capacitor C";
            y_label = "x_2 - Current Inductor L";

            hold off;
            plot(y(:,1), y(:,2), 'LineWidth', 2); hold on;
            plot(xref(1), xref(2), 'rx');

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
            tit = "Buck-Boost Converter Signal Command";
            x_label = "t - time (s)";
            y_label = "u - switch command";

            hold off;

            f = stairs(t, m, 'linew', 3); 

            hold on;
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

            f{1} = figure(1);
            self.plot_traj();
            
            f{2} = figure(2);
            self.plot_u_signal();
        end

    end
end