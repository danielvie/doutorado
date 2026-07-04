function res = p2(save_fig, nsim_in)

    if (nargin == 0)
        save_fig = false;
    end
    
    nsim = 100;
    if (nargin >= 1)
        nsim = nsim_in;
    end

    res = patino2(save_fig, nsim);
end