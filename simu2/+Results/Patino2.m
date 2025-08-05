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
        
        function plot_traj(self)
            % Plot 3D trajectory comparison (control ON vs OFF)
            
            % Extract state variables for both cases
            [vc1_on, vc2_on, i_l_on] = self.extract_states(self.states);
            [vc1_off, vc2_off, i_l_off] = self.extract_states(self.states_off);
            
            % Create 3D plot
            clf;
            plot3(vc1_on, vc2_on, i_l_on, 'LineWidth', 2);
            hold on;
            plot3(vc1_off, vc2_off, i_l_off, 'LineWidth', 2);
            plot3(self.target(1), self.target(2), self.target(3), 'rx', 'MarkerSize', 12, 'LineWidth', 3);
            grid on;

            % Formatting
            title("Multilevel Converter: Trajectory Comparison");
            xlabel("X_1: Voltage C_1 [V]");
            ylabel("X_2: Voltage C_2 [V]");
            zlabel("X_3: Current L [A]");
            legend('Control ON', 'Control OFF', 'Target', 'Location', 'best');
            self.apply_standard_formatting();
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
        
    end
    
    methods (Static)
        %% ========== STATIC UTILITY METHODS ==========
        
        function demo()
            % Demonstration of class capabilities
            fprintf('Patino2 Results Analysis Class\n');
            fprintf('Usage:\n');
            fprintf('  res = Results.Patino2(data);\n');
            fprintf('  res.plot_xi();           %% Plot state variables\n');
            fprintf('  res.plot_traj();         %% Plot 3D trajectory\n');
            fprintf('  res.plot_u_signals();    %% Plot control signals\n');
            fprintf('  stats = res.analyze_performance(); %% Performance analysis\n');
        end
        
    end
end