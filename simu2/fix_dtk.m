function [dtk_us_new] = fix_dtk(time_us, dtk_us, time_constraint_us)
    
    dtk_len = numel(dtk_us);
    ts_us_len = numel(time_us)+1;

    % create ts_us_ref
    ts_us_ref = zeros(1, dtk_len+2);
    ts_us_ref(end) = sum(time_us);
    for i = 1:dtk_len
        ts_us_ref(i+1) = ts_us_ref(i) + time_us(i);
    end

    % impose constraint on dtk_us based on time_us
    for i = 1:dtk_len
        if (time_us(i) + dtk_us(i) < time_constraint_us)
            dtk_us(i) = time_constraint_us - time_us(i);
        end
    end

    % adjust ts_us with new dtk
    ts_us = ts_us_ref;
    for i = 1:dtk_len
        ts_us(i+1) = ts_us(i+1) + dtk_us(i);
    end

    % impose time constraint for `ts_us`
    for i = 1:(ts_us_len-2)
        if (ts_us(i+1) - ts_us(i)) < time_constraint_us
            ts_us(i+1) = ts_us(i) + time_constraint_us;
        end
    end

    % adjust final time
    ts_us_end = ts_us(end);
    if ts_us(end-1) > ts_us_end
        ts_us(1:end-1) = ts_us(1:end-1)/ts_us(end-1)*(ts_us_end - time_constraint_us*dtk_len);
    end

    % impose time constraint for `ts_us`
    for i = 1:(ts_us_len-1)
        if (ts_us(i+1) - ts_us(i)) < time_constraint_us
            ts_us(i+1) = ts_us(i) + time_constraint_us;
        end
    end

    dtk_us_new = dtk_us*0;
    for i = 1:dtk_len
        dtk_us_new(i) = ts_us(i+1) - ts_us_ref(i+1);
    end

    % dbstop();

end