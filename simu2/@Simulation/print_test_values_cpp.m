function print_test_values_cpp(self, k, log_source)
    % print_test_values_cpp - Print controller values as C++ test assignments.
    %
    % Extracts key controller variables from a log entry and formats them
    % as ready-to-paste C++ code for embedded controller unit tests.
    % Output is also copied to the clipboard.
    %
    % Usage:
    %   s.print_test_values_cpp(5)              % from 'run' log (default)
    %   s.print_test_values_cpp(5, 'signal')    % from 'signal' log

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
            error('print_test_values_cpp: unknown log source "%s".', log_source);
    end

    % Validate index
    n_entries = size(log.x0, 1);
    assert(k >= 1 && k <= n_entries, ...
        'print_test_values_cpp: index k=%d out of range [1, %d]', k, n_entries);

    % --- Extract values ---
    K        = self.m_config.mpc.K;
    x_target = log.x_target(k, :)';
    x        = log.x0(k, :)';
    ek       = log.ek(k, :)';
    time_dur = self.get_time_us();       % nominal switching intervals [us]
    dtk_before = -K * ek;               % raw control law
    dtk_after  = log.dtk(k, :)';        % conditioned (from log)

    % --- Build output string ---
    out = build_output(k, log_source, K, x_target, x, ek, time_dur, dtk_before, dtk_after);

    % --- Print and copy to clipboard ---
    fprintf('%s', out);
    clipboard('copy', out);
    fprintf('(Copied to clipboard)\n');
end


% -------------------------------------------------------------------------
% Local helpers
% -------------------------------------------------------------------------

function out = build_output(k, log_source, K, x_target, x, ek, time_dur, dtk_before, dtk_after)
    N = numel(time_dur);                 % number of time_duration elements
    [p, n_states] = size(K);             % p rows, n_states cols
    max_idx = p * n_states - 1;          % for right-aligning indices
    idx_width = numel(num2str(max_idx)); % digit width for alignment

    out = '';

    out = [out, sprintf('\n// ============================================\n')];
    out = [out, sprintf('// C++ Test Values  (k = %d, log = %s)\n', k, log_source)];
    out = [out, sprintf('// ============================================\n\n')];

    % time_durations (uint32_t, no f suffix)
    out = [out, sprintf('// --- time_durations ---\n')];
    out = [out, sprintf('ds.size = %d;\n', N)];
    for i = 1:N
        out = [out, sprintf('ds.time_durations[%d] = %d;\n', i-1, time_dur(i))];
    end
    out = [out, sprintf('\n')];

    % x_target
    out = [out, sprintf('// --- x_target ---\n')];
    for i = 1:numel(x_target)
        out = [out, sprintf('ds.target[%d] = %.6gf;\n', i-1, x_target(i))];
    end
    out = [out, sprintf('\n')];

    % K (gain_k, row-major)
    out = [out, sprintf('// --- gain_k (K matrix, row-major) ---\n')];
    out = [out, sprintf('ds.gain_k.rows = %d;\n', p)];
    out = [out, sprintf('ds.gain_k.cols = %d;\n', n_states)];
    out = [out, sprintf('ds.gain_k.size = %d;\n', p * n_states)];
    out = [out, sprintf('ds.gain_k.is_valid = true;\n')];
    for r = 1:p
        for c = 1:n_states
            idx = (r-1) * n_states + (c-1);
            out = [out, sprintf('ds.gain_k.values[%*d] = %.6gf;\n', idx_width, idx, K(r, c))];
        end
    end
    out = [out, sprintf('\n')];

    % x (measured state / ADC readings)
    out = [out, sprintf('// --- x (measured state) ---\n')];
    adc_names = {'an3', 'an5', 'an6'};
    for i = 1:min(numel(x), numel(adc_names))
        out = [out, sprintf('float %s = %.6gf;\n', adc_names{i}, x(i))];
    end
    for i = (numel(adc_names)+1):numel(x)
        out = [out, sprintf('float x%d = %.6gf;\n', i, x(i))];
    end
    out = [out, sprintf('\n')];

    % Verification comments
    out = [out, sprintf('// --- Verification ---\n')];

    out = [out, '// Expected ek:       ['];
    for i = 1:numel(ek)
        if i > 1, out = [out, ', ']; end
        out = [out, sprintf('%.6g', ek(i))];
    end
    out = [out, sprintf(']\n')];

    out = [out, '// Expected dtk_raw:  ['];
    for i = 1:numel(dtk_before)
        if i > 1, out = [out, ', ']; end
        out = [out, sprintf('%.6g', dtk_before(i))];
    end
    out = [out, sprintf(']\n')];

    out = [out, '// Expected dtk_cond: ['];
    for i = 1:numel(dtk_after)
        if i > 1, out = [out, ', ']; end
        out = [out, sprintf('%.6g', dtk_after(i))];
    end
    out = [out, sprintf(']\n\n')];
end
