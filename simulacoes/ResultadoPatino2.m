classdef ResultadoPatino2
    properties
        vars
    end

    methods
        function self = ResultadoPatino2(vars)
            self.vars = vars;
        end
        
        function plot_xi(self)
            plotter.patino2_mpc.plot_xi(self.vars.t, self.vars.y);
        end

        function plot_traj(self)
            plotter.patino2_mpc.plot_traj(self.vars.y, self.vars.y_off, self.vars.config.x0, "Multilevel Converter Trajectory", "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]");
        end

        function plot_traj2(self)
            plotter.patino2_mpc.plot_traj(self.vars.y2, self.vars.y2_off, self.vars.config.x0, "Multilevel Converter Trajectory", "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]");
        end

        function plot_control_signal(self, ncycles)
            if (nargin == 1)
                ncycles = 10;
            end

            nelements = size(self.vars.y_off, 1) / self.vars.nsim;
            nelements = nelements * ncycles;
            plotter.patino2_mpc.plot_control_signal(self.vars.t_off(1:nelements), self.vars.m_off(1:nelements), self.vars.t(1:nelements), self.vars.m(1:nelements), "Multilevel Converter Control Signal", "time (s)", "mode");
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
            self.plot_control_signal(10);
        end

    end
end