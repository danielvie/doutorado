function z_create_lookup()
% z_create_lookup - Generate compact embedded lookup files from simulation
%
% Output files:
%   ../../../../embedded/esp32_idf/main/include/helper_datasetter.h
%   ../../../../embedded/esp32_idf/main/src/helper_datasetter.cpp

    clc;

    simulation = create_simulation();
    alpha_values = 0.10:0.01:0.90;
    lookup = collect_lookup(simulation, alpha_values);

    header_path = fullfile(project_root(), ...
        'embedded', 'esp32_idf', 'main', 'include', 'helper_datasetter.h');
    source_path = fullfile(project_root(), ...
        'embedded', 'esp32_idf', 'main', 'src', 'helper_datasetter.cpp');

    mode_patterns = build_mode_patterns(lookup);
    generator_config = build_generator_config(alpha_values, lookup, mode_patterns);

    header_text = build_header_text();
    source_text = build_source_text(generator_config);

    write_text_file(header_path, header_text);
    write_text_file(source_path, source_text);

    fprintf('Generated:\n');
    fprintf('  %s\n', header_path);
    fprintf('  %s\n', source_path);
end

function simulation = create_simulation()
    simulation = Simulation(Enums.SimName.LAB_CIRCUIT);

    config_mpc = simulation.get_config_mpc();
    config_mpc.Nd = 15;
    config_mpc.Np = 1;

    simulation.set_config_mpc(config_mpc);
end

function lookup = collect_lookup(simulation, alpha_values)
    alpha_count = numel(alpha_values);

    lookup = repmat(struct( ...
        'alpha', 0.0, ...
        'dataset_size', 0, ...
        'time_durations', zeros(1, 0), ...
        'modes_d4', zeros(1, 0), ...
        'modes_d5', zeros(1, 0), ...
        'modes_d6', zeros(1, 0), ...
        'target', zeros(1, 3), ...
        'gain_k', zeros(1, 0)), 1, alpha_count);

    for alpha_index = 1:alpha_count
        alpha_value = alpha_values(alpha_index);

        simulation.set_traj_phase_with_alpha(alpha_value);
        simulation.set_mpc();

        time_us = simulation.get_time_us();
        time_us = max(round(time_us), 7);

        [mode_d6, mode_d5, mode_d4] = simulation.get_mode_bin();
        target = simulation.get_target();
        gain_k = simulation.get_gain_k();

        lookup(alpha_index).alpha = alpha_value;
        lookup(alpha_index).dataset_size = numel(time_us);
        lookup(alpha_index).time_durations = reshape(time_us, 1, []);
        lookup(alpha_index).modes_d4 = reshape(mode_d4, 1, []);
        lookup(alpha_index).modes_d5 = reshape(mode_d5, 1, []);
        lookup(alpha_index).modes_d6 = reshape(mode_d6, 1, []);
        lookup(alpha_index).target = reshape(target, 1, []);
        lookup(alpha_index).gain_k = reshape(gain_k', 1, []);
    end
end

function mode_patterns = build_mode_patterns(lookup)
    mode_patterns = struct( ...
        'modes_d4', {}, ...
        'modes_d5', {}, ...
        'modes_d6', {});

    pattern_count = 0;

    for lookup_index = 1:numel(lookup)
        candidate_d4 = lookup(lookup_index).modes_d4;
        candidate_d5 = lookup(lookup_index).modes_d5;
        candidate_d6 = lookup(lookup_index).modes_d6;

        found_index = 0;
        for pattern_index = 1:pattern_count
            if isequal(mode_patterns(pattern_index).modes_d4, candidate_d4) && ...
               isequal(mode_patterns(pattern_index).modes_d5, candidate_d5) && ...
               isequal(mode_patterns(pattern_index).modes_d6, candidate_d6)
                found_index = pattern_index;
                break;
            end
        end

        if found_index == 0
            pattern_count = pattern_count + 1;
            mode_patterns(pattern_count).modes_d4 = candidate_d4; %#ok<AGROW>
            mode_patterns(pattern_count).modes_d5 = candidate_d5; %#ok<AGROW>
            mode_patterns(pattern_count).modes_d6 = candidate_d6; %#ok<AGROW>
        end
    end
end

function generator_config = build_generator_config(alpha_values, lookup, mode_patterns)
    alpha_count = numel(alpha_values);
    dataset_size = lookup(1).dataset_size;
    target_size = numel(lookup(1).target);
    gain_k_size = numel(lookup(1).gain_k);

    validate_lookup_consistency(lookup, dataset_size, target_size, gain_k_size);

    mode_pattern_index = zeros(1, alpha_count);
    for lookup_index = 1:alpha_count
        mode_pattern_index(lookup_index) = find_mode_pattern_index( ...
            lookup(lookup_index), mode_patterns);
    end

    generator_config = struct();
    generator_config.alpha_min = alpha_values(1);
    generator_config.alpha_max = alpha_values(end);
    generator_config.alpha_step = alpha_values(2) - alpha_values(1);
    generator_config.alpha_count = alpha_count;
    generator_config.alpha_tol = generator_config.alpha_step / 20.0;
    generator_config.dataset_size = dataset_size;
    generator_config.target_size = target_size;
    generator_config.gain_k_rows = 5;
    generator_config.gain_k_cols = 3;
    generator_config.gain_k_size = gain_k_size;
    generator_config.lookup = lookup;
    generator_config.mode_patterns = mode_patterns;
    generator_config.mode_pattern_index = mode_pattern_index;
end

function validate_lookup_consistency(lookup, dataset_size, target_size, gain_k_size)
    for lookup_index = 1:numel(lookup)
        if lookup(lookup_index).dataset_size ~= dataset_size
            error('Dataset size changed at alpha %.2f.', lookup(lookup_index).alpha);
        end

        if numel(lookup(lookup_index).target) ~= target_size
            error('Target size changed at alpha %.2f.', lookup(lookup_index).alpha);
        end

        if numel(lookup(lookup_index).gain_k) ~= gain_k_size
            error('Gain size changed at alpha %.2f.', lookup(lookup_index).alpha);
        end
    end
end

function pattern_index = find_mode_pattern_index(lookup_item, mode_patterns)
    for pattern_index = 1:numel(mode_patterns)
        if isequal(mode_patterns(pattern_index).modes_d4, lookup_item.modes_d4) && ...
           isequal(mode_patterns(pattern_index).modes_d5, lookup_item.modes_d5) && ...
           isequal(mode_patterns(pattern_index).modes_d6, lookup_item.modes_d6)
            return;
        end
    end

    error('Mode pattern not found for alpha %.2f.', lookup_item.alpha);
end

function header_text = build_header_text()
    lines = {
        '// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.'
        '// Generated by simu2/+z_run/+Demos/z_create_lookup.m'
        ''
        '#pragma once'
        ''
        '#include "signal_controller.h"'
        ''
        'void helper_set_dataset_from_alpha(DataSet *dataset, float alpha);'
    };

    header_text = join_lines(lines);
end

function source_text = build_source_text(generator_config)
    lines = {};
    lines{end+1} = '// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.';
    lines{end+1} = '// Generated by simu2/+z_run/+Demos/z_create_lookup.m';
    lines{end+1} = '';
    lines{end+1} = '#include "helper_datasetter.h"';
    lines{end+1} = '';
    lines{end+1} = '#include <cmath>';
    lines{end+1} = '';
    lines{end+1} = 'namespace {';
    lines{end+1} = sprintf('constexpr float alpha_min = %s;', cpp_float(generator_config.alpha_min, 2));
    lines{end+1} = sprintf('constexpr float alpha_max = %s;', cpp_float(generator_config.alpha_max, 2));
    lines{end+1} = sprintf('constexpr float alpha_step = %s;', cpp_float(generator_config.alpha_step, 2));
    lines{end+1} = sprintf('constexpr float alpha_tol = %s;', cpp_float(generator_config.alpha_tol, 4));
    lines{end+1} = sprintf('constexpr int alpha_count = %d;', generator_config.alpha_count);
    lines{end+1} = sprintf('constexpr uint32_t dataset_size = %d;', generator_config.dataset_size);
    lines{end+1} = sprintf('constexpr uint16_t gain_k_rows = %d;', generator_config.gain_k_rows);
    lines{end+1} = sprintf('constexpr uint16_t gain_k_cols = %d;', generator_config.gain_k_cols);
    lines{end+1} = sprintf('constexpr uint16_t gain_k_size = %d;', generator_config.gain_k_size);
    lines{end+1} = '';

    lines = append_table(lines, build_time_duration_table(generator_config));
    lines = append_table(lines, build_mode_pattern_index_table(generator_config));
    lines = append_table(lines, build_mode_pattern_table(generator_config, 'modes_d4_patterns', 'modes_d4'));
    lines = append_table(lines, build_mode_pattern_table(generator_config, 'modes_d5_patterns', 'modes_d5'));
    lines = append_table(lines, build_mode_pattern_table(generator_config, 'modes_d6_patterns', 'modes_d6'));
    lines = append_table(lines, build_target_table(generator_config));
    lines = append_table(lines, build_gain_table(generator_config));

    lines{end+1} = 'int helper_alpha_to_index(float alpha) {';
    lines{end+1} = '    if (alpha < alpha_min - alpha_tol || alpha > alpha_max + alpha_tol) {';
    lines{end+1} = '        return -1;';
    lines{end+1} = '    }';
    lines{end+1} = '';
    lines{end+1} = '    const float alpha_steps = (alpha - alpha_min) / alpha_step;';
    lines{end+1} = '    const int alpha_index = static_cast<int>(std::lround(alpha_steps));';
    lines{end+1} = '';
    lines{end+1} = '    if (alpha_index < 0 || alpha_index >= alpha_count) {';
    lines{end+1} = '        return -1;';
    lines{end+1} = '    }';
    lines{end+1} = '';
    lines{end+1} = '    const float alpha_expected = alpha_min + static_cast<float>(alpha_index) * alpha_step;';
    lines{end+1} = '    if (std::fabs(alpha - alpha_expected) > alpha_tol) {';
    lines{end+1} = '        return -1;';
    lines{end+1} = '    }';
    lines{end+1} = '';
    lines{end+1} = '    return alpha_index;';
    lines{end+1} = '}';
    lines{end+1} = '';
    lines{end+1} = 'void helper_apply_mode_pattern(DataSet *dataset, uint8_t pattern_index) {';
    lines{end+1} = '    for (uint32_t sample_index = 0; sample_index < dataset_size; ++sample_index) {';
    lines{end+1} = '        dataset->modes_d4[sample_index] = modes_d4_patterns[pattern_index][sample_index];';
    lines{end+1} = '        dataset->modes_d5[sample_index] = modes_d5_patterns[pattern_index][sample_index];';
    lines{end+1} = '        dataset->modes_d6[sample_index] = modes_d6_patterns[pattern_index][sample_index];';
    lines{end+1} = '    }';
    lines{end+1} = '}';
    lines{end+1} = '';
    lines{end+1} = '} // namespace';
    lines{end+1} = '';
    lines{end+1} = 'void helper_set_dataset_from_alpha(DataSet *dataset, float alpha) {';
    lines{end+1} = '    const int alpha_index = helper_alpha_to_index(alpha);';
    lines{end+1} = '    if (alpha_index < 0) {';
    lines{end+1} = '        return;';
    lines{end+1} = '    }';
    lines{end+1} = '';
    lines{end+1} = '    dataset->size = dataset_size;';
    lines{end+1} = '';
    lines{end+1} = '    for (uint32_t sample_index = 0; sample_index < dataset_size; ++sample_index) {';
    lines{end+1} = '        dataset->time_durations[sample_index] = time_duration_values[alpha_index][sample_index];';
    lines{end+1} = '    }';
    lines{end+1} = '';
    lines{end+1} = '    helper_apply_mode_pattern(dataset, mode_pattern_index[alpha_index]);';
    lines{end+1} = '';
    lines{end+1} = '    for (uint32_t target_index = 0; target_index < 3; ++target_index) {';
    lines{end+1} = '        dataset->target[target_index] = target_values[alpha_index][target_index];';
    lines{end+1} = '    }';
    lines{end+1} = '';
    lines{end+1} = '    dataset->gain_k.rows = gain_k_rows;';
    lines{end+1} = '    dataset->gain_k.cols = gain_k_cols;';
    lines{end+1} = '    dataset->gain_k.size = gain_k_size;';
    lines{end+1} = '    dataset->gain_k.is_valid = true;';
    lines{end+1} = '';
    lines{end+1} = '    for (uint32_t gain_index = 0; gain_index < gain_k_size; ++gain_index) {';
    lines{end+1} = '        dataset->gain_k.values[gain_index] = gain_k_values[alpha_index][gain_index];';
    lines{end+1} = '    }';
    lines{end+1} = '}';

    source_text = join_lines(lines);
end

function lines = build_time_duration_table(generator_config)
    lines = {
        sprintf('const uint32_t time_duration_values[alpha_count][dataset_size] = {')
    };

    for lookup_index = 1:generator_config.alpha_count
        values = generator_config.lookup(lookup_index).time_durations;
        lines{end+1} = sprintf('    {%s},', join_uint_values(values)); %#ok<AGROW>
    end

    lines{end+1} = '};';
    lines{end+1} = '';
end

function lines = build_mode_pattern_index_table(generator_config)
    lines = {
        'const uint8_t mode_pattern_index[alpha_count] = {'
    };

    values_per_line = 12;
    line_count = ceil(numel(generator_config.mode_pattern_index) / values_per_line);

    for line_index = 1:line_count
        start_index = (line_index - 1) * values_per_line + 1;
        end_index = min(line_index * values_per_line, numel(generator_config.mode_pattern_index));
        row_values = generator_config.mode_pattern_index(start_index:end_index) - 1;
        lines{end+1} = sprintf('    %s,', join_uint_values(row_values)); %#ok<AGROW>
    end

    lines{end+1} = '};';
    lines{end+1} = '';
end

function lines = build_mode_pattern_table(generator_config, table_name, field_name)
    pattern_count = numel(generator_config.mode_patterns);

    lines = {
        sprintf('const uint32_t %s[%d][dataset_size] = {', table_name, pattern_count)
    };

    for pattern_index = 1:pattern_count
        values = generator_config.mode_patterns(pattern_index).(field_name);
        lines{end+1} = sprintf('    {%s},', join_uint_values(values)); %#ok<AGROW>
    end

    lines{end+1} = '};';
    lines{end+1} = '';
end

function lines = build_target_table(generator_config)
    lines = {
        'const float target_values[alpha_count][3] = {'
    };

    for lookup_index = 1:generator_config.alpha_count
        values = generator_config.lookup(lookup_index).target;
        lines{end+1} = sprintf('    {%s},', join_float_values(values, 6)); %#ok<AGROW>
    end

    lines{end+1} = '};';
    lines{end+1} = '';
end

function lines = build_gain_table(generator_config)
    lines = {
        'const float gain_k_values[alpha_count][gain_k_size] = {'
    };

    for lookup_index = 1:generator_config.alpha_count
        values = generator_config.lookup(lookup_index).gain_k;
        lines{end+1} = sprintf('    {%s},', join_float_values(values, 7)); %#ok<AGROW>
    end

    lines{end+1} = '};';
    lines{end+1} = '';
end

function lines = append_table(lines, block_lines)
    for line_index = 1:numel(block_lines)
        lines{end+1} = block_lines{line_index}; %#ok<AGROW>
    end
end

function text = join_lines(lines)
    text = sprintf('%s\n', lines{:});
end

function text = join_uint_values(values)
    parts = cell(1, numel(values));
    for value_index = 1:numel(values)
        parts{value_index} = sprintf('%d', round(values(value_index)));
    end
    text = strjoin(parts, ', ');
end

function text = join_float_values(values, digits)
    parts = cell(1, numel(values));
    for value_index = 1:numel(values)
        parts{value_index} = cpp_float(values(value_index), digits);
    end
    text = strjoin(parts, ', ');
end

function text = cpp_float(value, digits)
    text = sprintf(['%0.', num2str(digits), 'f'], value);
    text = [text, 'f'];
end

function write_text_file(file_path, text)
    file_identifier = fopen(file_path, 'w');
    if file_identifier < 0
        error('Could not open file for writing: %s', file_path);
    end

    cleanup_guard = onCleanup(@() fclose(file_identifier)); %#ok<NASGU>
    fprintf(file_identifier, '%s', text);
end

function root_path = project_root()
    current_path = fileparts(mfilename('fullpath'));
    root_path = fullfile(current_path, '..', '..', '..');
    root_path = char(java.io.File(root_path).getCanonicalPath());
end
