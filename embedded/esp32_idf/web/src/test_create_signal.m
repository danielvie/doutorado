% Test script for create_signal.m
% Displays output for various duty cycles (alpha) to verify matching results
% with TypeScript implementation.

alphas = [0.4, 0.75, 0.1];

for a = alphas
    fprintf('=== Test for alpha = %.2f ===\n', a);
    [time_vector, mode_vector] = create_signal(a);
    
    fprintf('time_vector (us):  %s\n', strjoin(arrayfun(@num2str, time_vector, 'UniformOutput', false), ', '));
    fprintf('mode_vector (0b):  %s\n', strjoin(arrayfun(@num2str, mode_vector, 'UniformOutput', false), ', '));
    fprintf('\n');
end
