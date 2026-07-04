function vout = projecao_integrador_duplo(savefig_in)

    %{
        savefig: flag para salvar figuras em pdf
    %}

    savefig = false;
    if nargin >= 1
        savefig = savefig_in;
    end
    
    % PROJECAO INTEGRADOR DUPLO

    % modelo de predicao:
    %{
        e(tn) = Phi e(t0) + Gamma * dt
        Phi -> A
        Gamma -> B7
        dt -> u
    %}


    Phi   = [1, 6;
            0, 1];

    Gamma = [4, 3, -1; 
            1, 1, -1];

    % modelo discretizado com T = 0.1s

    config.A = Phi;
    config.B = Gamma;

    % ganho de realimentacao K usando DLQR
    config.Q = diag([1, 1]);
    config.R = diag([0.01, 0.01, 0.01]);

    % restricoes

    %{
        L dt >= c 
    %}

    Ts = [0, 2, 3, 5, 6];
    dtr = diff(Ts);

    t_on  = 1.625;
    t_off = 0.635;

    L = toeplitz([1, -1, 0, 0], [1, 0, 0]);

    c = [
        -dtr(1) + t_on;
        -dtr(2) + t_off;
        -dtr(3) + t_on;
        -dtr(4) + t_off;
    ];


    config.Sx = [0, 0];
    config.bx = 0;

    config.Su = -L;
    config.bu = -c;

    config.xbar = [-0.5; -1.0];
    config.ubar = [0; 0; 0];

    %{
        do controlador, tenho:
            K = dlqr(Phi,Gamma,Q,R);
        com
            Phi = [1, 6;
                0, 1]

            Gamma = [ 4, 3, -1;
                    1, 1, -1]
                    
            Q = [10, 0;
                0, 1]
                
            R = [1, 0, 0;
                0, 1, 0;
                0, 0, 1]
                
            K = [0.2314, 1.1329;
                0.0862, 0.6111;
                0.2042, 0.4325]
    %} 


    config.N = 1;
    v1 = create_projection(config);
    config.N = 2;
    v2 = create_projection(config);
    config.N = 4;
    v4 = create_projection(config);

    f1 = figure(1);
    clf;
    
    % deslocando origem 
    v1.D = v1.D + config.xbar;
    v2.D = v2.D + config.xbar;
    v4.D = v4.D + config.xbar;

    plotter.integrador.plot_projection(f1, v1, v2, v4, config.xbar);

    % plot(v.D);
    % txt = sprintf("projecao integrador duplo N:%d", config.N);
    % title(txt)
    % xlabel('x_1');
    % ylabel('x_2');
    
    vnames = who;
    vout = {};
    for i = 1:numel(vnames)
        vi = vnames{i};
        vout.(vi) = eval(vi);
    end
    

    if savefig
        disp('salvando figura em pdf');
        name = sprintf("graf_proj_integrador.pdf", config.N);
        save_figure(f1, name, "../LATEX_tese/Cap4/fig/");
    end
    
end

