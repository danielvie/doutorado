
A = [ 0.9713, 0.2192; -0.1707, 0.5857];
B = [2.4556; 0.9280];
Q = diag(2);
R = 1;
try
    disp('Trying dlqr(A, B, diag(2), 1)...');
    K = dlqr(A, B, Q, R);
    disp('K:'); disp(K);
catch ME
    disp('Error:'); disp(ME.message);
end

disp('Trying dlqr(A, B, eye(2), 1)...');
K2 = dlqr(A, B, eye(2), 1);
disp('K2:'); disp(K2);
