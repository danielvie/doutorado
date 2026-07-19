

H = [ 1,-1, 1
     -1, 2,-2
      1,-2, 4];

f = [-7;-3;-9];

A = [1,1,1];

b = 3;

lb = zeros(3,1);
x0 = [0;0;0];

% [x,fval,exitflag,output,lambda] = quadprog(H,f,A,b,Aeq,beq,lb,ub,x0,opt);

[x,fval,exitflag] = fun_quadprog(H,f,A,b,lb,x0)