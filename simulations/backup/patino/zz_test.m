%{
	Mode	u1 	u2 	u3
	0		0  	0 	0
	1		0  	0 	1
	2		0  	1 	0
	3		0  	1 	1
	4		1  	0 	0
	5		1  	0 	1
	6		1  	1 	0
	7		1  	1 	1
%}

syms x1 x2 x3 C1 C2 L E R

A = [
    -x3/C1,     x3/C1,        0
         0,    -x3/C2,    x3/C2
      x1/L, (x2-x1)/L, (E-x2)/L
];

Cte = [0; 0; -R/L*x3];

u0 = [0; 0; 0];
u1 = [0; 0; 1];
u2 = [0; 1; 0];
u3 = [0; 1; 1];
u4 = [1; 0; 0];
u5 = [1; 0; 1];
u6 = [1; 1; 0];
u7 = [1; 1; 1];

A0 = A*u0 + Cte;
A1 = A*u1 + Cte;
A2 = A*u2 + Cte;
A3 = A*u3 + Cte;
A4 = A*u4 + Cte;
A5 = A*u5 + Cte;
A6 = A*u6 + Cte;
A7 = A*u7 + Cte;

clc;
disp(' ');
printw(A0);
disp(' ');
printw(A1);
disp(' ');
printw(A2);
disp(' ');
printw(A3);
disp(' ');
printw(A4);
disp(' ');
printw(A5);
disp(' ');
printw(A6);
disp(' ');
printw(A7);
disp(' ');

function printw(M)
%     fprintf('%s = [\\matrix ', inputname(1));
%     
%     fprintf('%s@%s@%s',M(1),M(2),M(3));
%     
%     fprintf(' ]\n');
    disp(inputname(1));
    disp(simplify(M));
end
