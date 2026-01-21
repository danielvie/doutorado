classdef Proportional < Controllers.Controller
    properties
        K       % Gain matrix
        Nd = 1  % Downsampling factor (1 = every step)
        
        % Internal state
        counter
        last_dtk
    end
    
    methods
        function self = Proportional(K, Nd)
            if nargin > 0, self.K = K; end
            if nargin > 1, self.Nd = Nd; end
            self.reset();
        end
        
        function reset(self)
            % Initialize so the first step triggers a computation
            self.counter = self.Nd; 
            self.last_dtk = [];
        end
        
        function [dtk, exitflag, info] = compute_control(self, x, x_target)
            info = struct('time_qp', 0);
            
            % Check if we should compute or hold
            if self.counter < self.Nd
                % Hold previous control
                if isempty(self.last_dtk)
                    % Fallback for very first step if logic allows holding (should not happen with reset)
                    dtk = zeros(size(self.K, 1), 1); 
                else
                    dtk = self.last_dtk;
                end
                exitflag = 44; % "Held/Cached" status
                self.counter = self.counter + 1;
            else
                % Compute new control
                
                tic_start = tic;
                
                ek = x - x_target;
                dtk = -self.K * ek;
                
                info.time_qp = toc(tic_start);
                exitflag = 1;
                
                % Update state
                self.last_dtk = dtk;
                self.counter = 1; 
            end
        end
    end
end
