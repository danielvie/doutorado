
cont = 0;
freq = 10;

h = waitbar(0, 'Processing...');
for alpha = 0.001:0.001:0.999
    cont = rem(cont + 1, freq);
    if cont == 0
        waitbar(alpha/0.999, h, 'Processing...');
    end

    s.set_alpha_and_mpc_cached(alpha);
end
close(h);