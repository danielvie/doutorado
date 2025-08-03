classdef Patino2
    properties
        data
    end

    methods(Static)
        function plot_xi_helper(t, x, tit, x_la, y_la)
            plot(t, x);

            grid on;
            title(tit);
            xlabel(x_la);
            ylabel(y_la);

            set(gca,'fontsize', 15);
        end
    end

    methods
        function self = Patino2(data)
            self.data = data;
        end
        
        function plot_xi(self)
            disp(self.data);
            t = self.data.t;
            y = self.data.y;
            
            vc1 = y(:,1);
            vc2 = y(:,2);
            i_l = y(:,3);
            
            % plot results
            subplot(3, 1, 1);
            self.plot_xi_helper(t, vc1, "Multilevel Converter: X_1", "t - time(s)", "Voltage C_1 [V]");

            subplot(3, 1, 2);
            self.plot_xi_helper(t, vc2, "Multilevel Converter: X_2", "t - time(s)", "Voltage C_2 [V]");

            subplot(3, 1, 3);
            self.plot_xi_helper(t, i_l, "Multilevel Converter: X_3", "t - time(s)", "Current L [A]");
        end
        
        function plot_traj(self)

            % [y, t, m] = s.run(nsim);
            % [y_off, t_off, m_off] = s.run(nsim);

            % plot traj control ON
            y = self.data.y;
            y_off = self.data.y_off;
            
            % target
            x_target = self.data.s.m_config.mpc.x_target;

            vc1_ = y(:,1);
            vc2_ = y(:,2);
            i_l_ = y(:,3);

            vc1_off = y_off(:,1);
            vc2_off = y_off(:,2);
            i_l_off = y_off(:,3);

            clf;
            plot3(vc1_, vc2_, i_l_);
            hold on;
            plot3(vc1_off, vc2_off, i_l_off);
            plot3(x_target(1), x_target(2), x_target(3), 'rx', 'MarkerSize', 12);
            grid on;

            title("Multilevel Converter: Trajectory");
            xlabel("X_1: Voltage C_1 [V]");
            ylabel("X_2: Voltage C_2 [V]");
            zlabel("X_3: Current L [A]");

            legend('control ON', 'control OFF', 'Location', 'northeast');
            set(gca,'fontsize', 15);
        end
        
        function f = plot_u_signals(self, ncycles, skip)
            
            % default value for ncycles
            if (nargin == 1)
                disp('setting ncycles = 8');
                ncycles = 8;
            end

            if (nargin == 2)
                skip = 0;
            end

            
            % calculating npoints for u signal
            npoints = size(self.data.y_off, 1) / self.data.nsim;
            npoints = npoints * ncycles;
            
            % adjusting for when there are less poits than npoints
            size_yoff = max(size(self.data.y_off));
            size_y = max(size(self.data.y));
            if ( npoints > size_yoff || npoints > size_y )
                npoints = min([size_yoff, size_y]);
                fprintf('setting npoints to max value: %d\n', npoints);
            end

            % reading values
            t_off = self.data.t_off(1+skip:skip+npoints);
            m_off = self.data.m_off(1+skip:skip+npoints);
            t = self.data.t(1+skip:skip+npoints);
            m = self.data.m(1+skip:skip+npoints);
            tit = "Buck-Boost Converter: Control Signal";
            x_label = "time (s)";
            y_label = "mode";

            % plotting modes
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
    end
end