
a = [1,2,3,4,5];
b = [a;a;a;a;a;a;a;a;a];

sout_elements = arrayfun(@num2str, b, 'UniformOutput', false);

sout = strjoin(sout_elements, ',');

[m,n] = size(b);
sout = sprintf("%d;%d;%s;", m,n,sout);

disp(sout