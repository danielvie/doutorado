function test_industrial_solution()

    alpha = 0.1;
    T = 280;
    nSwitches = 3;
    
    [Omega, dtSwitch, tSwitch] = Utils.industrial_solution(alpha,nSwitches,T)
    
    print_bin(Omega, 1);
    print_bin(Omega, 2);
    print_bin(Omega, 3);
end

function print_bin(v, idx)
    txt = "";
    for i = 1:numel(v)
        vi = v(i)-1;
        vi_bin = dec2bin(vi, 3);
        txt = txt + " " + vi_bin(idx);
    end
    disp(txt);
end