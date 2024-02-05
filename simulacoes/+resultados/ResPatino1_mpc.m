classdef ResPatino1_mpc
    properties
        data
    end

    methods
        function self = ResPatino1_mpc(data)
            self.data = data;
        end

        function plot_traj(self)
            plotter.patino1_mpc.plot_traj(self.data.y, self.data.y_off, self.data.config.x0, "Buck-Boost Converter MPC", "x_1 - Voltage Capacitor C", "x_2 - Current Inductor L");
        end

        function plot_u_signal(self)
            ncycle = size(self.data.y_off, 1) / self.data.nsim;
            ncycle = ncycle * 8 -700;
            plotter.patino1_mpc.plot_u_signal(self.data.t_off(1:ncycle), self.data.m_off(1:ncycle), self.data.t(1:ncycle), self.data.m(1:ncycle), "Buck-Boost Converter: Control Signal", "time (s)", "mode");
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