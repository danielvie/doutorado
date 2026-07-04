function time_dt = compute_dt_time_signal(time)
    time_dt = zeros(1, numel(time)-1);
    time_dt(1) = round(time(2));
    temp_cumulative = 0;
    for i = 2:numel(time)-1
        dt_time = time(i) - temp_cumulative;
        dt_time = dt_time - round(rem(dt_time, 1));
        time_dt(i) = round(dt_time);
        temp_cumulative = temp_cumulative + time_dt(i);
    end
end