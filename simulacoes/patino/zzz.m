

a = 1;
b = 5;

dt = 1e-7;

for i = 1:200
    
    x = 0.5*(a+b);
    
    % eval
    res = (x^dt-1)/dt;
    
    if res < 1
        a = x;
    else
        b = x;
    end
    
end

disp([res, x, exp(1), x - exp(1)])

