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
    config.N = 3;
    v3 = create_projection(config);

    f1 = figure(1);
    clf;
    
    plot_projection(f1, v1, v2, v3, config.xbar);

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

function plot_projection(f, v1, v2, v3, xbar)

    clf;

    c1 = [1, 1, 1] * 0.7;
    c2 = [1, 1, 1] * 0.4;
    c3 = [1, 1, 1] * 0.2;

    % c1 = [0.06, 0.32, 0.69] * 1.3;
    % c2 = [0.06, 0.32, 0.69] * 0.9;
    % c3 = [0.06, 0.32, 0.69] * 0.7;

    plot(v3.D, 'color', c3);
    hold on;
    plot(v2.D, 'color', c2);
    plot(v1.D, 'color', c1);
    disp(xbar)
    plot(xbar(1),xbar(2), 'rx', 'markers', 12);
    hold off;

    % labels
    legend("N_p = 3", "N_p = 2", "N_p = 1");


    title('Double Integrator Feasibility Region')
    xlabel('x_1');
    ylabel('x_2');

    % ajustar tamanho da fonte
    ax = gca(f);
    set(ax,'fontsize', 17);
    % zoom(f, 0.7);
    

end