function t = teste_redundancia(S,b,c,d)
    options = optimoptions('linprog','Display','none');
    [x,~,exitflag] = linprog(-c,S,b,[],[],[],[],options);
    if exitflag == 1
        t = (c'*x - d);
    elseif exitflag == -3
        t = 1; % unbounded means it can go arbitrarily high, clearly not redundant and cuts the space
    else
        t = -1; 
    end
end