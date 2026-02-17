function print_test_values(self, k, log_source)
    % print_test_values - Print controller values from a log entry for test generation.
    %
    % Extracts and displays the key controller variables at a given log index,
    % useful for creating unit tests of the embedded controller logic.
    %
    % Usage:
    %   s.print_test_values(5)              % from 'run' log (default)
    %   s.print_test_values(5, 'signal')    % from 'signal' log
    %
    % Printed values:
    %   K                    - Gain matrix
    %   x_target             - Target state vector
    %   x                    - Measured state (x0)
    %   ek                   - Error vector (x - x_target)
    %   time_duration array  - Nominal switching intervals [us]
    %   dtk before cond.     - Raw control action (-K * ek)
    %   dtk after cond.      - Conditioned control action (from log)

    if nargin < 3
        log_source = 'run';
    end

    % Select log
    switch log_source
        case 'run'
            log = self.m_log.run;
        case 'signal'
            log = self.m_log.signal;
        otherwise
            error('print_test_values: unknown log source "%s". Use "run" or "signal".', log_source);
    end

    % Validate index
    n_entries = size(log.x0, 1);
    assert(k >= 1 && k <= n_entries, ...
        'print_test_values: index k=%d out of range [1, %d]', k, n_entries);

    % --- Extract values from log ---
    K        = self.m_config.mpc.K;
    x_target = log.x_target(k, :)';
    x        = log.x0(k, :)';
    ek       = log.ek(k, :)';

    % Nominal switching intervals (time_duration array)
    time_duration = self.get_time_us();

    % dtk before conditioning: recompute raw control law
    dtk_before = -K * ek;

    % dtk after conditioning: what was actually applied (from log)
    dtk_after = log.dtk(k, :)';

    % --- Print ---
    fprintf('\n');
    fprintf('========================================\n');
    fprintf('  Controller Test Values  (k = %d)\n', k);
    fprintf('  Log source: %s\n', log_source);
    fprintf('========================================\n\n');

    fprintf('K (gain matrix):\n');
    print_matrix(K);

    fprintf('x_target:\n');
    print_vector(x_target);

    fprintf('x (measured state):\n');
    print_vector(x);

    fprintf('ek (x - x_target):\n');
    print_vector(ek);

    fprintf('time_duration [us] (nominal switching intervals):\n');
    print_vector(time_duration(:));

    fprintf('dtk BEFORE conditioning (-K * ek):\n');
    print_vector(dtk_before);

    fprintf('dtk AFTER conditioning (logged):\n');
    print_vector(dtk_after);

    fprintf('========================================\n\n');
end


% -------------------------------------------------------------------------
% Local helpers
% -------------------------------------------------------------------------

function print_vector(v)
    fprintf('  [');
    for i = 1:numel(v)
        if i > 1, fprintf(', '); end
        fprintf('%.10g', v(i));
    end
    fprintf(']\n\n');
end

function print_matrix(M)
    [rows, cols] = size(M);
    for r = 1:rows
        fprintf('  [');
        for c = 1:cols
            if c > 1, fprintf(', '); end
            fprintf('%.10g', M(r, c));
        end
        fprintf(']\n');
    end
    fprintf('\n');
end
