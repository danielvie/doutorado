function ts = time_array_from_diff(t_diff)
    td_len = numel(t_diff);
    ts = zeros(1, td_len + 1);
    
    for i = 1:td_len
        ts(i+1) = ts(i) + t_diff(i);
    end
end