

% referencia
tr = config.Tr(2:end);
ur = config.ur;


N = 50;
x = [0, tr];
for i = 1:N
    x = [x, tr+x(end)];
end

y = [repmat(ur, [1, N+1]), ur(1)];

T = table();
T.x = x';
T.y = y';
T = T(T.x < t(end), :);


stairs(T.x, T.y, 'linew', 2);
hold on;

plot(t, u, '--', 'linew', 2);
hold off;

% xlim([0, 5])