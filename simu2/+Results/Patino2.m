classdef Patino2 < handle
    % Patino2 - Results visualization and analysis class for multilevel converter simulations
    % This class provides comprehensive plotting and analysis tools for MPC-controlled
    % multilevel converter simulations with control ON/OFF comparisons.
    
    properties
        data  % Simulation data structure
    end
    
    properties (Dependent)
        nsim          % Number of simulation cycles
        states        % State variables (control ON)
        states_off    % State variables (control OFF) 
        time          % Time vector (control ON)
        time_off      % Time vector (control OFF)
        modes         % Mode sequence (control ON)
        modes_off     % Mode sequence (control OFF)
        target        % MPC target state
    end
    
    methods
        function self = Patino2(data)
            % Constructor - Initialize with simulation data
            % Input: data - structure containing simulation results
            if nargin > 0
                self.data = data;
            end
        end
        
        %% ========== DEPENDENT PROPERTY GETTERS ==========
        
        function val = get.nsim(self)
            val = self.data.nsim;
        end
        
        function val = get.states(self)
            val = self.data.y;
        end
        
        function val = get.states_off(self)
            val = self.data.y_off;
        end
        
        function val = get.time(self)
            val = self.data.t;
        end
        
        function val = get.time_off(self)
            val = self.data.t_off;
        end
        
        function val = get.modes(self)
            val = self.data.m;
        end
        
        function val = get.modes_off(self)
            val = self.data.m_off;
        end
        
        function val = get.target(self)
            val = self.data.s.m_config.mpc.x_target;
        end
        
        %% ========== PUBLIC PLOTTING METHODS ==========
        
        function plot_xi(self)
            % Plot state variables vs time (3 subplots)
            disp(self.data);
            
            % Extract state variables
            [vc1, vc2, i_l] = self.extract_states(self.states);
            
            % Create subplots
            subplot(3, 1, 1);
            self.plot_state_helper(self.time, vc1, "Multilevel Converter: X_1", "Voltage C_1 [V]");

            subplot(3, 1, 2);
            self.plot_state_helper(self.time, vc2, "Multilevel Converter: X_2", "Voltage C_2 [V]");

            subplot(3, 1, 3);
            self.plot_state_helper(self.time, i_l, "Multilevel Converter: X_3", "Current L [A]");
        end
        
        function plot_traj(self, method)
            % Plot 3D trajectory comparison with multiple visualization options
            % Input: method - 'default', 'subplots', 'animated', 'projections', 'interactive'
            
            if nargin < 2, method = 'default'; end
            
            % Extract state variables for both cases
            [vc1_on, vc2_on, i_l_on] = self.extract_states(self.states);
            [vc1_off, vc2_off, i_l_off] = self.extract_states(self.states_off);
            
            switch lower(method)
                case 'default'
                    self.plot_traj_default(vc1_on, vc2_on, i_l_on, vc1_off, vc2_off, i_l_off);
                case 'subplots'
                    self.plot_traj_subplots(vc1_on, vc2_on, i_l_on, vc1_off, vc2_off, i_l_off);
                case 'animated'
                    self.plot_traj_animated(vc1_on, vc2_on, i_l_on, vc1_off, vc2_off, i_l_off);
                case 'projections'
                    self.plot_traj_projections(vc1_on, vc2_on, i_l_on, vc1_off, vc2_off, i_l_off);
                case 'interactive'
                    self.plot_traj_interactive(vc1_on, vc2_on, i_l_on, vc1_off, vc2_off, i_l_off);
                otherwise
                    error('Unknown method. Use: default, subplots, animated, projections, or interactive');
            end
        end
        
        function f = plot_u_signals(self, ncycles, skip)
            % Plot control signals (mode sequences) vs time
            % Inputs:
            %   ncycles - number of cycles to display (default: 8)
            %   skip - number of initial points to skip (default: 0)
            
            % Handle input arguments
            if nargin < 2, ncycles = 8; disp('setting ncycles = 8'); end
            if nargin < 3, skip = 0; end
            
            % Calculate data ranges
            [t_off, m_off, t_on, m_on] = self.prepare_signal_data(ncycles, skip);
            
            % Create plot
            f = stairs(t_off, m_off, 'LineWidth', 2);
            hold on;
            stairs(t_on, m_on, 'LineWidth', 2, 'LineStyle', '--');
            hold off;
            
            % Formatting
            grid on;
            title("Buck-Boost Converter: Control Signal Comparison");
            xlabel("Time (s)");
            ylabel("Mode");
            legend('Reference Trajectory', 'MPC Controlled', 'Location', 'best');
            self.apply_standard_formatting();
            self.fix_integer_yticks(f);
        end
        
        %% ========== DATA ANALYSIS METHODS ==========
        
        function stats = analyze_performance(self)
            % Analyze control performance metrics
            stats = struct();
            
            % State tracking errors
            error_on = self.states - self.target';
            error_off = self.states_off - self.target';
            
            stats.rmse_on = sqrt(mean(sum(error_on.^2, 2)));
            stats.rmse_off = sqrt(mean(sum(error_off.^2, 2)));
            stats.improvement = (stats.rmse_off - stats.rmse_on) / stats.rmse_off * 100;
            
            % Final state errors
            stats.final_error_on = norm(self.states(end, :) - self.target');
            stats.final_error_off = norm(self.states_off(end, :) - self.target');
            
            % Time to convergence (within 5% of target)
            threshold = 0.05 * norm(self.target);
            errors_on = sqrt(sum(error_on.^2, 2));
            errors_off = sqrt(sum(error_off.^2, 2));
            
            conv_idx_on = find(errors_on < threshold, 1);
            conv_idx_off = find(errors_off < threshold, 1);
            
            if isempty(conv_idx_on)
                stats.convergence_time_on = inf;
            else
                stats.convergence_time_on = self.time(conv_idx_on);
            end
            
            if isempty(conv_idx_off)
                stats.convergence_time_off = inf;
            else
                stats.convergence_time_off = self.time_off(conv_idx_off);
            end
            
            fprintf('Performance Analysis:\n');
            fprintf('  RMSE (Control ON):  %.4f\n', stats.rmse_on);
            fprintf('  RMSE (Control OFF): %.4f\n', stats.rmse_off);
            fprintf('  Improvement: %.2f%%\n', stats.improvement);
            fprintf('  Convergence time (ON):  %.6f s\n', stats.convergence_time_on);
            fprintf('  Convergence time (OFF): %.6f s\n', stats.convergence_time_off);
        end
        
    end
    
    methods (Access = private)
        %% ========== PRIVATE HELPER METHODS ==========
        
        function [vc1, vc2, i_l] = extract_states(~, states)
            % Extract individual state variables from state matrix
            vc1 = states(:, 1);
            vc2 = states(:, 2);
            i_l = states(:, 3);
        end
        
        function plot_state_helper(self, t, x, title_str, ylabel_str)
            % Helper method for plotting individual state variables
            plot(t, x, 'LineWidth', 2);
            grid on;
            title(title_str);
            xlabel("Time (s)");
            ylabel(ylabel_str);
            self.apply_standard_formatting();
        end
        
        function apply_standard_formatting(~)
            % Apply consistent formatting to plots
            set(gca, 'FontSize', 15);
        end
        
        function fix_integer_yticks(~, f)
            % Remove non-integer values from Y axis ticks
            v = f.Parent.YTick;
            p = abs(v - floor(v)) < 0.1;  % indices for integer values
            f.Parent.YTick = v(p);
        end
        
        function [t_off, m_off, t_on, m_on] = prepare_signal_data(self, ncycles, skip)
            % Prepare time and mode data for signal plotting
            
            % Calculate points per dataset
            modes_per_cycle_off = floor(size(self.states_off, 1) / self.nsim);
            modes_per_cycle_on = floor(size(self.states, 1) / self.nsim);
            
            npoints_off = min(floor(modes_per_cycle_off * ncycles), size(self.states_off, 1));
            npoints_on = min(floor(modes_per_cycle_on * ncycles), size(self.states, 1));
            
            % Extract data with bounds checking
            end_idx_off = min(skip + npoints_off, size(self.states_off, 1));
            end_idx_on = min(skip + npoints_on, size(self.states, 1));
            
            t_off = self.time_off(1+skip:end_idx_off);
            m_off = self.modes_off(1+skip:end_idx_off);
            t_on = self.time(1+skip:end_idx_on);
            m_on = self.modes(1+skip:end_idx_on);
            
            if npoints_off ~= floor(modes_per_cycle_off * ncycles)
                fprintf('Adjusted npoints_off to max value: %d\n', npoints_off);
            end
            if npoints_on ~= floor(modes_per_cycle_on * ncycles)
                fprintf('Adjusted npoints_on to max value: %d\n', npoints_on);
            end
        end
        
        %% ========== TRAJECTORY PLOTTING METHODS ==========
        
        function plot_traj_default(self, vc1_on, vc2_on, i_l_on, vc1_off, vc2_off, i_l_off)
            % Default 3D plot with improved axis handling
            clf;
            plot3(vc1_on, vc2_on, i_l_on, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
            hold on;
            plot3(vc1_off, vc2_off, i_l_off, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
            plot3(self.target(1), self.target(2), self.target(3), 'rx', 'MarkerSize', 12, 'LineWidth', 3);
            
            % Set fixed axis limits to prevent data clipping
            all_vc1 = [vc1_on; vc1_off; self.target(1)];
            all_vc2 = [vc2_on; vc2_off; self.target(2)];
            all_il = [i_l_on; i_l_off; self.target(3)];
            
            margin = 0.1; % 10% margin
            xlim([min(all_vc1) - margin*abs(min(all_vc1)), max(all_vc1) + margin*abs(max(all_vc1))]);
            ylim([min(all_vc2) - margin*abs(min(all_vc2)), max(all_vc2) + margin*abs(max(all_vc2))]);
            zlim([min(all_il) - margin*abs(min(all_il)), max(all_il) + margin*abs(max(all_il))]);
            
            grid on;
            title("3D Trajectory Comparison (Fixed Limits)");
            xlabel("X_1: Voltage C_1 [V]");
            ylabel("X_2: Voltage C_2 [V]");
            zlabel("X_3: Current L [A]");
            legend('Control ON', 'Control OFF', 'Target', 'Location', 'best');
            self.apply_standard_formatting();
            % view(45, 30); % Set a good viewing angle
            view(-15, 35);
        end
        
        function plot_traj_subplots(self, vc1_on, vc2_on, i_l_on, vc1_off, vc2_off, i_l_off)
            % 2D projections in subplots (easier to analyze)
            clf;
            
            % X1 vs X2 projection
            subplot(2, 2, 1);
            plot(vc1_on, vc2_on, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
            hold on;
            plot(vc1_off, vc2_off, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
            plot(self.target(1), self.target(2), 'rx', 'MarkerSize', 12, 'LineWidth', 3);
            grid on;
            title("X_1 vs X_2");
            xlabel("X_1: Voltage C_1 [V]");
            ylabel("X_2: Voltage C_2 [V]");
            legend('Control ON', 'Control OFF', 'Target', 'Location', 'best');
            
            % X1 vs X3 projection
            subplot(2, 2, 2);
            plot(vc1_on, i_l_on, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
            hold on;
            plot(vc1_off, i_l_off, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
            plot(self.target(1), self.target(3), 'rx', 'MarkerSize', 12, 'LineWidth', 3);
            grid on;
            title("X_1 vs X_3");
            xlabel("X_1: Voltage C_1 [V]");
            ylabel("X_3: Current L [A]");
            
            % X2 vs X3 projection
            subplot(2, 2, 3);
            plot(vc2_on, i_l_on, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
            hold on;
            plot(vc2_off, i_l_off, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
            plot(self.target(2), self.target(3), 'rx', 'MarkerSize', 12, 'LineWidth', 3);
            grid on;
            title("X_2 vs X_3");
            xlabel("X_2: Voltage C_2 [V]");
            ylabel("X_3: Current L [A]");
            
            % 3D plot in the 4th subplot
            subplot(2, 2, 4);
            plot3(vc1_on, vc2_on, i_l_on, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
            hold on;
            plot3(vc1_off, vc2_off, i_l_off, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
            plot3(self.target(1), self.target(2), self.target(3), 'rx', 'MarkerSize', 12, 'LineWidth', 3);
            grid on;
            title("3D View");
            xlabel("X_1");
            ylabel("X_2");
            zlabel("X_3");
            view(45, 30);
            
            sgtitle("Trajectory Analysis: Multiple Projections");
        end
        
        function plot_traj_animated(self, vc1_on, vc2_on, i_l_on, vc1_off, vc2_off, i_l_off)
            % Animated trajectory showing evolution over time
            clf;
            
            % Set up the plot
            h_on = plot3(vc1_on(1), vc2_on(1), i_l_on(1), 'b-', 'LineWidth', 2);
            hold on;
            h_off = plot3(vc1_off(1), vc2_off(1), i_l_off(1), 'r-', 'LineWidth', 2);
            h_target = plot3(self.target(1), self.target(2), self.target(3), 'rx', 'MarkerSize', 12, 'LineWidth', 3);
            
            % Current position markers
            h_marker_on = plot3(vc1_on(1), vc2_on(1), i_l_on(1), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
            h_marker_off = plot3(vc1_off(1), vc2_off(1), i_l_off(1), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
            
            % Set axis limits
            all_vc1 = [vc1_on; vc1_off; self.target(1)];
            all_vc2 = [vc2_on; vc2_off; self.target(2)];
            all_il = [i_l_on; i_l_off; self.target(3)];
            
            margin = 0.1;
            xlim([min(all_vc1) - margin*abs(min(all_vc1)), max(all_vc1) + margin*abs(max(all_vc1))]);
            ylim([min(all_vc2) - margin*abs(min(all_vc2)), max(all_vc2) + margin*abs(max(all_vc2))]);
            zlim([min(all_il) - margin*abs(min(all_il)), max(all_il) + margin*abs(max(all_il))]);
            
            grid on;
            title("Animated Trajectory Evolution");
            xlabel("X_1: Voltage C_1 [V]");
            ylabel("X_2: Voltage C_2 [V]");
            zlabel("X_3: Current L [A]");
            legend([h_on, h_off, h_target], 'Control ON', 'Control OFF', 'Target', 'Location', 'best');
            view(-15, 35);
            
            % Animation
            n_points = min(length(vc1_on), length(vc1_off));
            step = max(1, floor(n_points/100)); % Show about 100 frames
            
            for i = 1:step:n_points
                % Update trajectory lines
                set(h_on, 'XData', vc1_on(1:i), 'YData', vc2_on(1:i), 'ZData', i_l_on(1:i));
                set(h_off, 'XData', vc1_off(1:i), 'YData', vc2_off(1:i), 'ZData', i_l_off(1:i));
                
                % Update current position markers
                set(h_marker_on, 'XData', vc1_on(i), 'YData', vc2_on(i), 'ZData', i_l_on(i));
                set(h_marker_off, 'XData', vc1_off(i), 'YData', vc2_off(i), 'ZData', i_l_off(i));
                
                title(sprintf("Animated Trajectory Evolution (Step %d/%d)", i, n_points));
                drawnow;
                pause(0.05); % Adjust speed as needed
            end
        end
        
        function plot_traj_projections(self, vc1_on, vc2_on, ~, vc1_off, vc2_off, ~)
            % Large 2D projections with time coloring
            clf;
            
            % Create time vectors for coloring
            t_on_norm = linspace(0, 1, length(vc1_on));
            t_off_norm = linspace(0, 1, length(vc1_off));
            
            % X1 vs X2 projection with time coloring
            scatter(vc1_on, vc2_on, 30, t_on_norm, 'filled', 'DisplayName', 'Control ON');
            hold on;
            scatter(vc1_off, vc2_off, 30, t_off_norm, 'filled', 'Marker', 's', 'DisplayName', 'Control OFF');
            plot(self.target(1), self.target(2), 'rx', 'MarkerSize', 15, 'LineWidth', 3, 'DisplayName', 'Target');
            
            colorbar;
            colormap('parula');
            grid on;
            title("State Space Trajectory (X_1 vs X_2) - Color shows time progression");
            xlabel("X_1: Voltage C_1 [V]");
            ylabel("X_2: Voltage C_2 [V]");
            legend('Location', 'best');
            self.apply_standard_formatting();
        end
        
        function plot_traj_interactive(self, vc1_on, vc2_on, i_l_on, vc1_off, vc2_off, i_l_off)
            % Interactive plot with data cursor and rotate3d
            clf;
            
            plot3(vc1_on, vc2_on, i_l_on, 'LineWidth', 2, 'Color', [0 0.4470 0.7410], 'DisplayName', 'Control ON');
            hold on;
            plot3(vc1_off, vc2_off, i_l_off, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980], 'DisplayName', 'Control OFF');
            plot3(self.target(1), self.target(2), self.target(3), 'rx', 'MarkerSize', 12, 'LineWidth', 3, 'DisplayName', 'Target');
            
            % Add start and end markers
            plot3(vc1_on(1), vc2_on(1), i_l_on(1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'DisplayName', 'Start (ON)');
            plot3(vc1_on(end), vc2_on(end), i_l_on(end), 'gs', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'DisplayName', 'End (ON)');
            plot3(vc1_off(1), vc2_off(1), i_l_off(1), 'mo', 'MarkerSize', 10, 'MarkerFaceColor', 'm', 'DisplayName', 'Start (OFF)');
            plot3(vc1_off(end), vc2_off(end), i_l_off(end), 'ms', 'MarkerSize', 10, 'MarkerFaceColor', 'm', 'DisplayName', 'End (OFF)');
            
            grid on;
            title("Interactive 3D Trajectory - Use mouse to rotate, zoom, pan");
            xlabel("X_1: Voltage C_1 [V]");
            ylabel("X_2: Voltage C_2 [V]");
            zlabel("X_3: Current L [A]");
            legend('Location', 'best');
            self.apply_standard_formatting();
            
            % Enable interactive tools
            rotate3d on;
            datacursormode on;
            
            % Set a good initial view
            view(45, 30);
            
            fprintf('Interactive mode enabled:\n');
            fprintf('- Drag to rotate the view\n');
            fprintf('- Scroll to zoom\n');
            fprintf('- Right-click and drag to pan\n');
            fprintf('- Click on data points to see values\n');
        end
        
    end
    
    methods (Static)
        %% ========== STATIC UTILITY METHODS ==========
        
        function help()
            % Demonstration of class capabilities
            fprintf('Patino2 Results Analysis Class\n');
            fprintf('==============================\n\n');
            fprintf('Basic Usage:\n');
            fprintf('  res = Results.Patino2(data);\n\n');
            fprintf('Plotting Methods:\n');
            fprintf('  res.plot_xi();                    %% State variables vs time\n');
            fprintf('  res.plot_u_signals();             %% Control signals\n\n');
            fprintf('Trajectory Visualization Options:\n');
            fprintf('  res.plot_traj();                  %% Default 3D (fixed limits)\n');
            fprintf('  res.plot_traj(''subplots'');        %% 2D projections + 3D\n');
            fprintf('  res.plot_traj(''animated'');        %% Animated evolution\n');
            fprintf('  res.plot_traj(''projections'');     %% Time-colored 2D\n');
            fprintf('  res.plot_traj(''interactive'');     %% Interactive 3D\n\n');
            fprintf('Analysis:\n');
            fprintf('  stats = res.analyze_performance(); %% Performance metrics\n\n');
            fprintf('Trajectory Method Descriptions:\n');
            fprintf('  - default:     Fixed axis limits to prevent clipping\n');
            fprintf('  - subplots:    Multiple 2D projections for detailed analysis\n');
            fprintf('  - animated:    Shows trajectory evolution over time\n');
            fprintf('  - projections: Time-colored scatter plot (X1 vs X2)\n');
            fprintf('  - interactive: Mouse controls for rotation/zoom/pan\n');
        end
        
    end
end