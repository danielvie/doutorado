classdef ResPatino2_phase
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
        function self = ResPatino2_phase(data)
            self.data = data;
        end
        
        function plot_xi(self)
            t = self.data.t;
            y = self.data.y;

            vc1 = y(:,1);
            vc2 = y(:,2);
            i_l = y(:,3);

            subplot(3, 1, 1);
            self.plot_xi_helper(t, vc1, "Multilevel Converter: X_1", "t - time(s)", "Voltage C_1 [V]");

            subplot(3, 1, 2);
            self.plot_xi_helper(t, vc2, "Multilevel Converter: X_2", "t - time(s)", "Voltage C_2 [V]");

            subplot(3, 1, 3);
            self.plot_xi_helper(t, i_l, "Multilevel Converter: X_3", "t - time(s)", "Current L [A]");
        end

        function plot_traj(self)
            y = self.data.y;

            tit = "Multilevel Converter: Trajectory";
            x_la = "X_1: Voltage C_1 [V]";
            y_la = "X_2: Voltage C_2 [V]";
            z_la = "X_3: Current L [A]";

            vc1_ = y(:,1);
            vc2_ = y(:,2);
            i_l_ = y(:,3);

            % h(1) = plot3(vc1_, vc2_, i_l_);
            plot3(vc1_, vc2_, i_l_);
            % hold off;

            grid on;

            title(tit);
            xlabel(x_la);
            ylabel(y_la);
            zlabel(z_la);

            set(gca,'fontsize', 15);
            % legend(h, 'MPC_{off}');
        end

        function plot_u_signal(self)
            i = self.data.t < self.data.cfg.Ts(end);

            t = self.data.t(i);
            m = self.data.m(i);
            tit = "Multilevel Converter: Input Signal";
            x_label = "t - time(s)";
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
            self.plot_xi();
            
            f{2} = figure(2);
            self.plot_traj();
            
            f{3} = figure(3);
            self.plot_u_signal();
        end

    end
end
