

function z_play()
    a = 1;
    b = 2;
    sum = a + b;

    vars = get_vars();
    disp('vars:');
    disp(vars);
    fprintf("the sum of %d and %d is %d\n", a, b, sum);
end

function vars_out = get_vars()
    vars_out = evalin('caller', 'who');
end