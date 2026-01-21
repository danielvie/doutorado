classdef BuckBoostPlotter < handle
    % BuckBoostPlotter - Visualization for Buck-Boost Converter Simulation
    
    properties
        sim_data  % Instance of Results.SimulationData
    end
    
    methods
        function self = BuckBoostPlotter(sim_data)
            if ~isa(sim_data, 'Results.SimulationData')
                error('Input must be a Results.SimulationData object');
            end
            self.sim_data = sim_data;
        end
        
        function plot_states(self)
            % Plots the 3 state variables (vC1, vC2, iL)
            [v1, v2, iL] = self.extract_states(self.sim_data.y);
            t = self.sim_data.t;
            
            clf;
            subplot(3, 1, 1);
            self.plot_signal(t, v1, "Voltage C_1 [V]");
            
            subplot(3, 1, 2);
            self.plot_signal(t, v2, "Voltage C_2 [V]");
            
            subplot(3, 1, 3);
            self.plot_signal(t, iL, "Current L [A]");
        end
        
        function plot_trajectory_comparison(self)
            % 3D Phase Portrait comparing Control ON vs OFF
            
            [v1_on, v2_on, i_on] = self.extract_states(self.sim_data.y);
            [v1_off, v2_off, i_off] = self.extract_states(self.sim_data.y_off);
            target = self.sim_data.target;
            
            clf;
            plot3(v1_on, v2_on, i_on, 'b-', 'LineWidth', 1.5, 'DisplayName', 'MPC ON');
            hold on;
            if ~isempty(v1_off)
                plot3(v1_off, v2_off, i_off, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Open Loop');
                
                % Add start/end markers for clarity
                plot3(v1_off(1), v2_off(1), i_off(1), 'ro', 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
                plot3(v1_off(end), v2_off(end), i_off(end), 'ms', 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
            end
            

            disp(target)
            if ~isempty(target)
                plot3(target(1), target(2), target(3), 'rx', 'MarkerSize', 15, 'LineWidth', 3, 'DisplayName', 'Target');
            end
            
            grid on;
            xlabel('$v_{C1}$ [V]', 'Interpreter', 'latex');
            ylabel('$v_{C2}$ [V]', 'Interpreter', 'latex');
            zlabel('$i_L$ [A]', 'Interpreter', 'latex');
            title('Phase Space Trajectory');
            legend('Location', 'best');
            view(45, 30);
        end
        
        function plot_control_signals(self, start_idx, num_samples)
            % Step plot of modes
            % Inputs:
            %   start_idx (optional): Index to start plotting from (default: 1)
            %   num_samples (optional): Number of samples to plot (default: all)
            
            t = self.sim_data.t;
            m = self.sim_data.m;
            
            % Argument handling
            if nargin < 2 || isempty(start_idx), start_idx = 1; end
            if nargin < 3 || isempty(num_samples), num_samples = length(m) - start_idx + 1; end
            
            % Calculate valid range
            end_idx = min(start_idx + num_samples - 1, length(m));
            range = start_idx:end_idx;
            
            % Check if range is valid
            if isempty(range)
                warning('BuckBoostPlotter: Invalid range for control signals');
                return;
            end
            
            clf;
            stairs(t(range), m(range), 'LineWidth', 2);
            xlabel('Time [s]');
            ylabel('Switching Mode');
            title(sprintf('Control Action Sequence (Interval: %d to %d)', start_idx, end_idx));
            grid on;
            ylim([min(m)-1, max(m)+1]);
            xlim([t(start_idx), t(end_idx)]);
        end
        
        function plot_trajectory_animated(self)
            % Animated trajectory showing evolution over time
            [v1_on, v2_on, i_on] = self.extract_states(self.sim_data.y);
            [v1_off, v2_off, i_off] = self.extract_states(self.sim_data.y_off);
            target = self.sim_data.target;
            
            clf;
            
            % Setup lines
            h_on = plot3(v1_on(1), v2_on(1), i_on(1), 'b-', 'LineWidth', 2, 'DisplayName', 'MPC ON');
            hold on;
            h_off = plot3(v1_off(1), v2_off(1), i_off(1), 'r-', 'LineWidth', 2, 'DisplayName', 'Open Loop');
            h_target = plot3(target(1), target(2), target(3), 'k+', 'MarkerSize', 15, 'LineWidth', 2, 'DisplayName', 'Target');
            
            % Setup markers
            h_head_on = plot3(v1_on(1), v2_on(1), i_on(1), 'bo', 'MarkerFaceColor', 'b', 'HandleVisibility', 'off');
            h_head_off = plot3(v1_off(1), v2_off(1), i_off(1), 'ro', 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
            
            grid on;
            xlabel('$v_{C1}$ [V]', 'Interpreter', 'latex');
            ylabel('$v_{C2}$ [V]', 'Interpreter', 'latex');
            zlabel('$i_L$ [A]', 'Interpreter', 'latex');
            title('Trajectory Evolution');
            legend('Location', 'best');
            view(45, 30);
            
            % Set fixed limits
            all_v1 = [v1_on; v1_off; target(1)];
            all_v2 = [v2_on; v2_off; target(2)];
            all_i  = [i_on; i_off; target(3)];
            margin = 0.1;
            
            xlim([min(all_v1), max(all_v1)] + [-1, 1]*margin*range(all_v1));
            ylim([min(all_v2), max(all_v2)] + [-1, 1]*margin*range(all_v2));
            zlim([min(all_i), max(all_i)] + [-1, 1]*margin*range(all_i));
            
            % Animation Loop
            n_frames = 100;
            len = min(length(v1_on), length(v1_off));
            idx_sequence = round(linspace(1, len, n_frames));
            
            for k = idx_sequence
                set(h_on, 'XData', v1_on(1:k), 'YData', v2_on(1:k), 'ZData', i_on(1:k));
                set(h_off, 'XData', v1_off(1:k), 'YData', v2_off(1:k), 'ZData', i_off(1:k));
                
                set(h_head_on, 'XData', v1_on(k), 'YData', v2_on(k), 'ZData', i_on(k));
                set(h_head_off, 'XData', v1_off(k), 'YData', v2_off(k), 'ZData', i_off(k));
                
                drawnow limitrate;
                pause(0.01);
            end
        end
        
        function plot_trajectory_projections(self)
             % 2D Projections of the trajectory
            [v1_on, v2_on, i_on] = self.extract_states(self.sim_data.y);
            [v1_off, v2_off, i_off] = self.extract_states(self.sim_data.y_off);
            target = self.sim_data.target;
            
            clf;
            
            % X-Y (vC1 - vC2)
            subplot(2,2,1);
            plot(v1_on, v2_on, 'b'); hold on;
            plot(v1_off, v2_off, 'r');
            plot(target(1), target(2), 'k+');
            xlabel('vC1'); ylabel('vC2'); grid on; title('vC1 vs vC2');
            
            % X-Z (vC1 - iL)
            subplot(2,2,2);
            plot(v1_on, i_on, 'b'); hold on;
            plot(v1_off, i_off, 'r');
            plot(target(1), target(3), 'k+');
            xlabel('vC1'); ylabel('iL'); grid on; title('vC1 vs iL');
            
            % Y-Z (vC2 - iL)
            subplot(2,2,3);
            plot(v2_on, i_on, 'b'); hold on;
            plot(v2_off, i_off, 'r');
            plot(target(2), target(3), 'k+');
            xlabel('vC2'); ylabel('iL'); grid on; title('vC2 vs iL');
            
            % 3D
            subplot(2,2,4);
            plot3(v1_on, v2_on, i_on, 'b'); hold on;
            plot3(v1_off, v2_off, i_off, 'r');
            plot3(target(1), target(2), target(3), 'k+');
            grid on; view(45,30); title('3D');
            
            sgtitle('Trajectory Projections');
        end
        
    end
    
    methods (Access = private)
        function [v1, v2, iL] = extract_states(~, y)
            if size(y, 2) < 3
                error('BuckBoostPlotter expects at least 3 states (v1, v2, iL)');
            end
            v1 = y(:, 1);
            v2 = y(:, 2);
            iL = y(:, 3);
        end
        
        function plot_signal(~, t, y, label)
            plot(t, y, 'LineWidth', 1.5);
            grid on;
            ylabel(label);
            xlabel('Time [s]');
            set(gca, 'FontSize', 12);
        end
    end
end
