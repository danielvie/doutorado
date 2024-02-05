classdef ResPatino1
    properties
        data
    end

    methods
        function self = ResPatino1(data)
            self.data = data;
        end

        function plot_traj(self)
            plotter.patino1.plot_traj(self.data.y, self.data.c.xref, "Buck-Boost Converter: Cyclic Trajectory", "x_1 - Voltage Capacitor C", "x_2 - Current Inductor L");
        end

        function plot_u_signal(self)
            plotter.patino1.plot_u_signal(self.data.t, self.data.m, "Buck-Boost Converter Signal Command", "t - time (s)", "u - switch command");
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