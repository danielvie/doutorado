

% time values
time_us    = [0   46.6667   93.3333  140.0000  186.6667  233.3333  280.0000];
time_us_dt = [46.6667   46.6667   46.6667   46.6667   46.6667   46.6667];

time_us_dt_rounded = arrayfun(@round, time_us_dt);

time_us_constructed = construct_signal(time_us_dt_rounded);
compare_time(time_us, time_us_constructed);


% fix time drift
time_us_dt_rounded_fixed = time_us_dt_rounded;
for i = 1:numel(time_us)-i
    ti_c = time_us_constructed(i+1);
    ti_us = time_us(i+1);
    ti_diff = round(ti_c - ti_us);
    if ti_diff > 0
        time_us_dt_rounded_fixed(i) = time_us_dt_rounded_fixed(i) - ti_diff;
    end
end

time_us_constructed = construct_signal(time_us_dt_rounded_fixed);
for i = 1:numel(time_us)-i
    ti_c = time_us_constructed(i+1);
    ti_us = time_us(i+1);
    ti_diff = round(ti_c - ti_us);
    if ti_diff > 0
        time_us_dt_rounded_fixed(i) = time_us_dt_rounded_fixed(i) - ti_diff;
    end
end

disp('dfasdfasdf');
time_us_constructed_fixed = construct_signal(time_us_dt_rounded_fixed);
compare_time(time_us, time_us_constructed_fixed);

   

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