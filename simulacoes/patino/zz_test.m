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
    -x3/C1, x3/C1, 0
    0, -x3/C2, x3/C2
    x1/L, (x2-x1)/L, (E-x2)/L
];

Cte = [0;0;-R/L*x3];

m0 = [0; 0; 0];
m1 = [0; 0; 1];
m2 = [0; 1; 0];
m3 = [0; 1; 1];
m4 = [1; 0; 0];
m5 = [1; 0; 1];
m6 = [1; 1; 0];
m7 = [1; 1; 1];

A0 = A*m0 + Cte;
A1 = A*m1 + Cte;
A2 = A*m2 + Cte;
A3 = A*m3 + Cte;
A4 = A*m4 + Cte;
A5 = A*m5 + Cte;
A6 = A*m6 + Cte;
A7 = A*m7 + Cte;

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