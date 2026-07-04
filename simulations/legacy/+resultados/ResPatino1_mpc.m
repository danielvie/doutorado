classdef ResPatino1_mpc
    properties
        data
    end

    methods
        function self = ResPatino1_mpc(data)
            self.data = data;
        end

        function plot_traj(self)

            y = self.data.y;
            y_off = self.data.y_off;
            x0 = self.data.config.x0;
            tit = "Buck-Boost Converter MPC";
            x_label = "x_1 - Voltage Capacitor C";
            y_label = "x_2 - Current Inductor L";

            plot(y_off(:,1), y_off(:,2), 'linew', 1.2);
            hold on;
            plot(y(:,1), y(:,2), 'linew', 1.2);

            % plot marcadores
            plot(y(1,1), y(1,2), 'ro', 'markers', 10, 'linew', 1.2);
            plot(y(end,1), y(end,2), 'k.', 'markers', 30);
            plot(x0(1), x0(2), 'rx', 'linew', 2, 'markers', 16);

            legend('trajectory', 'start', 'end', 'target x_0', 'location', 'southeast');

            hold off;
            grid on;
            axis equal;
            title(tit);
            xlabel(x_label);
            ylabel(y_label);
            set(gca,'fontsize', 15);
            legend('mpc off', 'mpc on')
        end

        function plot_u_signal(self)
            ncycle = size(self.data.y_off, 1) / self.data.nsim;
            ncycle = ncycle * 8 -700;

            t_off = self.data.t_off(1:ncycle);
            m_off = self.data.m_off(1:ncycle);
            t = self.data.t(1:ncycle);
            m = self.data.m(1:ncycle);
            tit = "Buck-Boost Converter: Control Signal";
            x_label = "time (s)";
            y_label = "mode";

            f = stairs(t_off, m_off, 'linew', 2);
            hold on;
            stairs(t, m, 'linew', 2, 'linestyle', '--');
            hold off;
            
            grid on;
            title(tit);
            xlabel(x_label);
            ylabel(y_label);
            set(gca,'fontsize', 15);
            legend('modes target trajectory', 'modes simulation');

            % removing the values that are not integers in Y axis
            v = f.Parent.YTick;
            
            % indices for integer
            p = abs(v - floor(v)) < 0.1;
            
            % update yticks
            f.Parent.YTick = v(p);
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