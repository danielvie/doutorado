function mostra_dwell()
    y2 = evalin('base', 'y2');
    tr = evalin('base', 'tr');
    p  = evalin('base', 'p');

    d  = y2.logsout.get('dtk').Values.Data(1:4,:)';

    TT = zeros(4,3);
    for i = 1:3
        di = d(:,i);

        tr_ = zeros(p,1);

        % aplicando diferenca de tempo calculada pelo controle
        for j = 1:p
            tr_(j) = tr(j) + di(j);
        end

        TT(:,i) = diff([0;tr_;6]);
    end

    TT
end