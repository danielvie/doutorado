function print_test_values(self, k, log_source)
    % print_test_values - Print controller values from a log entry for test generation.
    %
    % Extracts and displays the key controller variables at a given log index,
    % useful for creating unit tests of the embedded controller logic.
    % Output is also copied to the clipboard.
    %
    % Usage:
    %   s.print_test_values(5)              % from 'run' log (default)
    %   s.print_test_values(5, 'signal')    % from 'signal' log

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

    % --- Build output string ---
    out = build_output(k, log_source, K, x_target, x, ek, time_duration, dtk_before, dtk_after);

    % --- Print and copy to clipboard ---
    fprintf('%s', out);
    clipboard('copy', out);
    fprintf('(Copied to clipboard)\n');
end


% -------------------------------------------------------------------------
% Local helpers
% -------------------------------------------------------------------------

function out = build_output(k, log_source, K, x_target, x, ek, time_duration, dtk_before, dtk_after)
    out = '';
    out = [out, sprintf('\n')];
    out = [out, sprintf('========================================\n')];
    out = [out, sprintf('  Controller Test Values  (k = %d)\n', k)];
    out = [out, sprintf('  Log source: %s\n', log_source)];
    out = [out, sprintf('========================================\n\n')];

    out = [out, sprintf('K (gain matrix):\n')];
    out = [out, format_matrix(K)];

    out = [out, sprintf('x_target:\n')];
    out = [out, format_vector(x_target)];

    out = [out, sprintf('x (measured state):\n')];
    out = [out, format_vector(x)];

    out = [out, sprintf('ek (x - x_target):\n')];
    out = [out, format_vector(ek)];

    out = [out, sprintf('time_duration [us] (nominal switching intervals):\n')];
    out = [out, format_vector(time_duration(:))];

    out = [out, sprintf('dtk BEFORE conditioning (-K * ek):\n')];
    out = [out, format_vector(dtk_before)];

    out = [out, sprintf('dtk AFTER conditioning (logged):\n')];
    out = [out, format_vector(dtk_after)];

    out = [out, sprintf('========================================\n\n')];
end

function s = format_vector(v)
    s = '  [';
    for i = 1:numel(v)
        if i > 1, s = [s, ', ']; end
        s = [s, sprintf('%.10g', v(i))];
    end
    s = [s, sprintf(']\n\n')];
end

function s = format_matrix(M)
    s = '';
    [rows, cols] = size(M);
    for r = 1:rows
        s = [s, '  ['];
        for c = 1:cols
            if c > 1, s = [s, ', ']; end
            s = [s, sprintf('%.10g', M(r, c))];
        end
        s = [s, sprintf(']\n')];
    end
    s = [s, sprintf('\n')];
end
