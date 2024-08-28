
function z_play()
    
    r = evalin('caller', 'r');
    l1 = r.data.log1;
    l2 = r.data.log2;

    nl1 = numel(l1);
    imax = 1;
    tmax = -1;
    tt = [];
    for i = 1:nl1
        li = l1{i};
        
        tt = [tt; li.time_quadprog];

        if i < 3
            continue;
        end
        
        if li.time_quadprog > tmax
            tmax = li.time_quadprog;
            vmax = li;
        end

    end
    
    v = vmax;
    t = tmax;
    
    assignin('caller', 'v', v);
    assignin('caller', 't', t);
    assignin('caller', "tt", tt);

end
