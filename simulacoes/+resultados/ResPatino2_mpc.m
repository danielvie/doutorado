classdef ResPatino2_mpc
    properties
        data
    end

    methods
        function self = ResPatino2_mpc(data)
            self.data = data;
        end
        
        function plot_xi(self)
            plotter.patino2_mpc.plot_xi(self.data.t, self.data.y);
        end

        function plot_traj(self)
            plotter.patino2_mpc.plot_traj(self.data.y, self.data.y_off, self.data.config.x0, "Multilevel Converter Trajectory", "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]");
        end

        function plot_traj2(self)
            plotter.patino2_mpc.plot_traj(self.data.y2, self.data.y2_off, self.data.config.x0, "Multilevel Converter Trajectory", "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]");
        end

        function plot_u_signal(self, ncycles)
            if (nargin == 1)
                ncycles = 10;
            end

            nelements = size(self.data.y_off, 1) / self.data.nsim;
            nelements = nelements * ncycles;
            plotter.patino2_mpc.plot_u_signal(self.data.t_off(1:nelements), self.data.m_off(1:nelements), self.data.t(1:nelements), self.data.m(1:nelements), "Multilevel Converter Control Signal", "time (s)", "mode");
        end
        
        function f = plot(self)
            f = {};

            f{1} = figure(1);
            self.plot_xi();
            
            f{2} = figure(2);
            self.plot_traj();
            
            f{3} = figure(3);
            self.plot_traj2();
            
            f{4} = figure(4);
            self.plot_u_signal(10);
        end

    end
end