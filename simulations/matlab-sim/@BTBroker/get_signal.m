function get_signal(self)
    
    % read values
    tu = self.simulation.get_time_us();
    mo = self.simulation.get_mode();
    
    % display time/mode
    fprintf('time: '); fprintf('%5.0f, ', tu); fprintf('\n');
    fprintf('mode: '); fprintf('%5.0f, ', mo); fprintf('\n');
end