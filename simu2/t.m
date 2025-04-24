

% time values
time_us    = [0   46.6667   93.3333  140.0000  186.6667  233.3333  280.0000];
time_us_dt = [46.6667   46.6667   46.6667   46.6667   46.6667   46.6667];

time_us_dt_rounded = arrayfun(@round, time_us_dt);

time_us_constructed = construct_signal(time_us_dt_rounded);
compare_time(time_us, time_us_constructed);

time_us_dt_new = Utils.compute_dt_time_signal(time_us);

time_us_constructed_new = construct_signal(time_us_dt_new);
disp('New time vector:');
compare_time(time_us, time_us_constructed_new);



% function time_dt = construct_dt_time_signal(time)
%     time_dt = zeros(1, numel(time)-1);
%     time_dt(1) = round(time(2));
%     temp_cumulative = 0;
%     for i = 2:numel(time)-1
%         dt_time = time(i) - temp_cumulative;
%         dt_time = dt_time - round(rem(dt_time, 1));
%         time_dt(i) = round(dt_time);
%         temp_cumulative = temp_cumulative + time_dt(i);
%     end
% end
   

function time = construct_signal(time_dt)
    time = zeros(1, numel(time_dt)+1);
    for i = 1:numel(time_dt)
        time(i+1) = time(i) + time_dt(i);
    end
end

function compare_time(time_a, time_b)
    if numel(time_a) ~= numel(time_b)
        error('Time vectors have different lengths.');
    end
    
    time_diff = time_a - time_b;
    time_diff_rounded = arrayfun(@round, time_diff);
    
    % create table with first line time_a, second line time_b, third line time_diff
    time = [time_a; time_b; time_diff; time_diff_rounded];
    tab = table(time);
    disp(tab);
end