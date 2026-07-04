function xr = get_xr()

    y1 = evalin('base', 'y1');

    t = y1.logsout.get('t').Values.Data;
    u = y1.logsout.get('u').Values.Data;
    x = y1.logsout.get('x').Values.Data;

    % diff tempo
    ini = 1;

    dt = abs(diff(t(ini:end))) > 0.01;
    p  = find(dt == 1, 2, 'last');

    ini = p(1);
    plot(u(ini:end-1));

    % encontrando referencias
    pu = abs(diff(u(ini:end)))> 0.8;

    xx = x(ini:end,:);
    xr = xx(pu,:);

    plot(xx(:,1));


end