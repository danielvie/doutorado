function print_test_values_cpp(self, k, log_source)
    % print_test_values_cpp - Print controller values as C++ test assignments.
    %
    % Extracts key controller variables from a log entry and formats them
    % as ready-to-paste C++ code for embedded controller unit tests.
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

    N = numel(time_dur);                 % number of time_duration elements
    [p, n_states] = size(K);             % p rows, n_states cols
    max_idx = p * n_states - 1;          % for right-aligning indices
    idx_width = numel(num2str(max_idx)); % digit width for alignment

    % --- Print C++ code ---
    fprintf('\n// ============================================\n');
    fprintf('// C++ Test Values  (k = %d, log = %s)\n', k, log_source);
    fprintf('// ============================================\n\n');

    % time_durations (uint32_t, no f suffix)
    fprintf('// --- time_durations ---\n');
    fprintf('ds.size = %d;\n', N);
    for i = 1:N
        fprintf('ds.time_durations[%d] = %d;\n', i-1, time_dur(i));
    end
    fprintf('\n');

    % x_target
    fprintf('// --- x_target ---\n');
    for i = 1:numel(x_target)
        fprintf('ds.target[%d] = %.6gf;\n', i-1, x_target(i));
    end
    fprintf('\n');

    % K (gain_k, row-major)
    fprintf('// --- gain_k (K matrix, row-major) ---\n');
    fprintf('ds.gain_k.rows = %d;\n', p);
    fprintf('ds.gain_k.cols = %d;\n', n_states);
    fprintf('ds.gain_k.size = %d;\n', p * n_states);
    fprintf('ds.gain_k.is_valid = true;\n');
    for r = 1:p
        for c = 1:n_states
            idx = (r-1) * n_states + (c-1);
            fprintf('ds.gain_k.values[%*d] = %.6gf;\n', idx_width, idx, K(r, c));
        end
    end
    fprintf('\n');

    % x (measured state / ADC readings)
    fprintf('// --- x (measured state) ---\n');
    adc_names = {'an3', 'an5', 'an6'};
    for i = 1:min(numel(x), numel(adc_names))
        fprintf('float %s = %.6gf;\n', adc_names{i}, x(i));
    end
    % fallback for states beyond 3
    for i = (numel(adc_names)+1):numel(x)
        fprintf('float x%d = %.6gf;\n', i, x(i));
    end
    fprintf('\n');

    % Verification comments
    fprintf('// --- Verification ---\n');

    fprintf('// Expected ek:       [');
    for i = 1:numel(ek)
        if i > 1, fprintf(', '); end
        fprintf('%.6g', ek(i));
    end
    fprintf(']\n');

    fprintf('// Expected dtk_raw:  [');
    for i = 1:numel(dtk_before)
        if i > 1, fprintf(', '); end
        fprintf('%.6g', dtk_before(i));
    end
    fprintf(']\n');

    fprintf('// Expected dtk_cond: [');
    for i = 1:numel(dtk_after)
        if i > 1, fprintf(', '); end
        fprintf('%.6g', dtk_after(i));
    end
    fprintf(']\n\n');
end
