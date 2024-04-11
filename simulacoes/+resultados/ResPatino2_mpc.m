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
            % plotter.patino2_mpc.plot_traj(self.data.y2, self.data.y2_off, self.data.config.x0, "Multilevel Converter Trajectory", "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]");
            y = self.data.y;
            y_off = self.data.y_quant; 
            x0 = self.data.config.x0; 
            tit = "Multilevel converter traj"; 
            x_label = "V_{c1} [V]"; 
            y_label = "V_{c2} [V]"; 
            z_label = "I_{L} [A]"; 

            yo1 = y_off(:,1);
            yo2 = y_off(:,2);
            yo3 = y_off(:,3);

            y1 = y(:,1);
            y2 = y(:,2);
            y3 = y(:,3);

            plot3(yo1, yo2, yo3);
            hold on;
            plot3(y1, y2, y3);

            % plot marcadores
            plot3(y1(1), y2(1), y3(1), 'ro', 'markers', 15, 'linew', 2); % start point
            plot3(yo1(end), yo2(end), yo3(end), 'k*', 'markers', 15, 'linew', 2); % end point
            plot3(y1(end), y2(end), y3(end), 'k.', 'markers', 50); % end point
            plot3(x0(1), x0(2), x0(3), 'rx', 'markers', 25, 'linew', 3); % target x_0

            legend('trajectory MPC off', 'trajectory MPC on', 'start', 'end MPC off', 'end MPC on', 'target x_0', 'location', 'southeast');

            hold off;
            grid on;
            title(tit)
            xlabel(x_label);
            ylabel(y_label);
            zlabel(z_label);
            set(gca,'fontsize', 15);



        end

        function plot_u_signal(self, ncycles)
            if (nargin == 1)
                ncycles = 10;
            end

            nelements = size(self.data.y_off, 1) / self.data.nsim;
            nelements = nelements * ncycles;
            plotter.patino2_mpc.plot_u_signal(self.data.t_off(1:nelements), self.data.m_off(1:nelements), self.data.t(1:nelements), self.data.m(1:nelements), "Multilevel Converter Control Signal", "time (s)", "mode");
        end
        
        function plot_xi_quant(self)
            t = self.data.t;
            y = self.data.y;
            t_quant = self.data.t_quant;
            y_quant = self.data.y_quant;

            subplot(3,1,1);
            self.plot_xi_helper(t, y(:,1), t_quant, y_quant(:,1), 'Voltage C_1 Multilevel Converter', 't - time(s)', 'V_{c1} [V]')
            subplot(3,1,2);
            self.plot_xi_helper(t, y(:,2), t_quant, y_quant(:,2), 'Voltage C_2 Multilevel Converter', 't - time(s)', 'V_{c2} [V]')
            subplot(3,1,3);
            self.plot_xi_helper(t, y(:,3), t_quant, y_quant(:,3), 'Current i_L Multilevel Converter', 't - time(s)', 'i_{L} [A]')
        end
        
        function plot_traj_quant(self)
            plotter.patino2_mpc.plot_traj(self.data.y_quant, self.data.y_off, self.data.config.x0, "Multilevel Converter Trajectory", "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]");
        end
        

        function plot_xi_helper(self, t, yi, t_quant, yi_quant, tit, x_label, y_label)
            plot(t, yi); hold on;
            plot(t_quant, yi_quant); hold off;


            grid on;
            title(tit)
            xlabel(x_label);
            ylabel(y_label);
            set(gca,'fontsize', 15);

        end

        function f = plot(self)
            f = {};

            % f{1} = figure(1);
            % self.plot_xi();
            
            % f{2} = figure(2);
            % self.plot_traj();
            
            % f{3} = figure(3);
            % self.plot_traj2();
            
            % f{4} = figure(4);
            % self.plot_u_signal(10);
            
            f{1} = figure(1);
            self.plot_xi_quant();
            
            f{2} = figure(2);
            self.plot_traj_quant();
        end

    end
end