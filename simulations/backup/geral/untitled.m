
clear all
A = 1:10;

for i = A
    txt = sprintf('bla %s', num2str(i));
    disp(txt)
end