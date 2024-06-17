classdef ResPatino2_mpc_phase
    properties
        data
    end
    
    methods(Static)
        function plot_xi_helper(t, yi, t_quant, yi_quant, tit, x_label, y_label)
            disp('dentro de xi_helper');
            plot(t, yi); hold on;
            % plot(t_quant, yi_quant); hold off;

            grid on;
            title(tit)
            xlabel(x_label);
            ylabel(y_label);
            set(gca,'fontsize', 15);
            disp('fim de xi_helper');
        end

        function plot_traj_helper(Y, Y2, x0, tit, x_label, y_label, z_label, leg)
            y1 = Y(:,1);
            y2 = Y(:,2);
            y3 = Y(:,3);

            y_1 = Y2(:,1);
            y_2 = Y2(:,2);
            y_3 = Y2(:,3);

            plot3(y1, y2, y3);
            hold on;
            plot3(y_1, y_2, y_3);

            % plot marcadores
            plot3(y1(1), y2(1), y3(1), 'ro', 'markers', 15, 'linew', 2); % start point
            plot3(y1(end), y2(end), y3(end), 'k.', 'markers', 50); % end point
            plot3(y_1(end), y_2(end), y_3(end), 'k*', 'markers', 15, 'linew', 2); % end point
            plot3(x0(1), x0(2), x0(3), 'rx', 'markers', 25, 'linew', 3); % target x_0

            legend(leg{:});

            hold off;
            grid on;
            title(tit)
            xlabel(x_label);
            ylabel(y_label);
            zlabel(z_label);
            set(gca,'fontsize', 15);
        end
    end

    methods
        function self = ResPatino2_mpc_phase(data)
            self.data = data;
        end
        
        function plot_xi(self)

            t = self.data.t;
            y = self.data.y;

            subplot(3,1,1);
            self.plot_xi_helper(t, y(:,1), 'Voltage C_1 Multilevel Converter', 't - time(s)', 'V_{c1} [V]')
            subplot(3,1,2);
            self.plot_xi_helper(t, y(:,2), 'Voltage C_2 Multilevel Converter', 't - time(s)', 'V_{c2} [V]')
            subplot(3,1,3);
            self.plot_xi_helper(t, y(:,3), 'Current i_L Multilevel Converter', 't - time(s)', 'i_{L} [A]')

        end

        function plot_traj(self)
            y = self.data.y;
            y_off = self.data.y_off;
            x0 = self.data.config.x0;
            tit = "Multilevel Converter Trajectory";
            x_label = "V_{c1} [V]";
            y_label = "V_{c2} [V]";
            z_label = "I_{L} [A]";
            leg = {'trajectory MPC off', 'trajectory MPC on', 'start', 'end MPC off', 'end MPC on', 'target x_0', 'location', 'southeast'};

            self.plot_traj_helper(y_off, y, x0, tit, x_label, y_label, z_label, leg);
        end

        function plot_traj2(self)
            % plotter.patino2_mpc_phase.plot_traj(self.data.y2, self.data.y2_off, self.data.config.x0, "Multilevel Converter Trajectory", "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]");
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

            t_off = self.data.t_off(1:nelements);
            m_off = self.data.m_off(1:nelements);
            t = self.data.t(1:nelements);
            m = self.data.m(1:nelements);
            tit = "Multilevel Converter Control Signal";
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

            leg = {'trajectory MPC', 'trajectory MPC quant', 'start', 'end MPC', 'end MPC quant', 'target x_0', 'location', 'southeast'};
            self.plot_traj_helper(self.data.y, self.data.y_quant, self.data.config.x0, "Multilevel Converter Trajectory", "V_{c1} [V]", "V_{c2} [V]", "I_{L} [A]", leg);

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
