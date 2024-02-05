classdef ResPatino2
    properties
        data
    end

    methods
        function self = ResPatino2(data)
            self.data = data;
        end
        
        function plot_xi(self)
            plotter.patino2.plot_xi(self.data.t, self.data.y);
        end

        function plot_traj(self)
            plotter.patino2.plot_traj(self.data.y, "Multilevel Converter: Trajectory", "X_1: Voltage C_1 [V]", "X_2: Voltage C_2 [V]", "X_3: Current L [A]");
        end

        function plot_u_signal(self)
            i = self.data.t < self.data.cfg.Ts(end);
            plotter.patino2.plot_u_signal(self.data.t(i), self.data.m(i), "Multilevel Converter: Input Signal", "t - time(s)", "u - switch command");
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