
function [x,fval,exitflag] = fun_quadprog(H,f,A,b,lb,x0)
    
    Aeq = [];
    beq = [];
    ub  = [];
    opt = optimoptions('quadprog','Algorithm','active-set');

    [x,fval,exitflag,~,~] = quadprog(H,f,A,b,Aeq,beq,lb,ub,x0,opt);

end