function [u,t] = fn_comando_u(ur, tr, T, dtk, tempo)
    
    % encontrando N
    N = numel(tr);    

    % calculando tempo relativo ( 0 <= t <= T )
    t = rem(tempo, T);
    
    % aplicando diferenca de tempo calculada pelo controle
    for i = 1:numel(dtk)
        tr(i) = tr(i) + dtk(i);
    end
    
    % encontrando comando de controle
    pos = 1;
    for i = 1:N
        if tr(i) > t
            pos = i;
            break;
        end
    end
    
    % retornando comando de controle
    u   = ur(pos);
