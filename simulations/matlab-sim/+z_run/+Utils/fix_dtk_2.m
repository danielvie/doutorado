function [dtk_us_new] = fix_dtk_2(time_us, dtk_us, time_constraint_us)
    
    ts_us_len = numel(time_us) + 1;
    ts_us = zeros(1, ts_us_len);

    % limit dtk_us min max
    dtk_us = min(max(dtk_us, -150), 150);

    % construct ts_us vector
    for i = 1:ts_us_len-1
        ts_us(i+1) = ts_us(i) + time_us(i);
    end
    
    % return nominal if is valid
    is_valid =@(k) test_dtk_is_valid(time_us, dtk_us, time_constraint_us, k);
    if is_valid(1.0)
        dtk_us_new = dtk_us;
        return;
    end
    
    % binary search
    a = 0;
    b = 1;
    tol = 0.001;
    max_iter = 10;
    
    for i = 1:max_iter
        x = (a+b)/2;
        if is_valid(x)
            % fprintf("[is valid], x: %f, a: %f, b: %f\n", x, a, b);
            a = x;
        else
            % fprintf("[is NOT valid], x: %f, a: %f, b: %f\n", x, a, b);
            b = x;
        end
        
        % exit condition
        if (abs(b-a) < tol)
            break;
        end
    end
    
    x = a;
    
    dtk_us_new = dtk_us*x;

    tss = create_ts(time_us, dtk_us*x);

    fprintf("result x: %f\n", x);

end

function ts_us = create_ts(time_us, dtk_us)
    ts_us_len = numel(time_us) + 1;
    ts_us = zeros(1, ts_us_len);

    % construct ts_us vector
    for i = 1:ts_us_len-1
        ts_us(i+1) = ts_us(i) + time_us(i);
    end

    % apply dtk
    for i = 1:ts_us_len-2
        ts_us(i+1) = ts_us(i+1) + dtk_us(i);
    end

end

function valid = test_dtk_is_valid(time_us, dtk_us, time_constraint_us, k)
    time_us_len = numel(time_us);

    valid = time_us(1) + k*dtk_us(1) > time_constraint_us;
    for i = 2:(time_us_len-1)
        valid = valid && (time_us(i) + k*dtk_us(i) - k*dtk_us(i-1) > time_constraint_us);
    end
    valid = valid && (time_us(time_us_len) - k*dtk_us(time_us_len-1) > time_constraint_us);
end