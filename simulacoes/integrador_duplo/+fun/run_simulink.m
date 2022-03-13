function yout = run_simulink(x0)
    % gravando valor de condicao inicial no workspace
    assignin('base', 'x0', x0);

    yout = sim('mod_integrador');
end