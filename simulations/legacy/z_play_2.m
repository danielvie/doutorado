
function z_play_2()
    % creating `sim` object
    
    an6 = [
        465, 309
        1000, 853
        1444, 1289
        1986, 1816
        2503, 2343
        3101, 3271
    ];

    an5 = [
        554, 394
        1055, 899
        1413, 1256
        2029, 1865
        2577, 2428
        2973, 3030
    ];

    an4 = [
        573, 412
        1017, 860
        1443, 1281
        2054, 1887
        2543, 2384
        2958, 3003
    ];
    
    f = plot(an4(:,1), an4(:, 2), '-*', 'linew', 2);
    hold on;
    plot(an5(:,1), an5(:, 2), '-*', 'linew', 2);
    plot(an6(:,1), an6(:, 2), '-*', 'linew', 2);
    hold off;
    grid on;
    axis equal;
    legend('an4', 'an5', 'an6');
    
    assignin('base', 'f', f);

end
