function vout = projecao_patino1(savefig_in)

    savefig = false;
    
    if nargin >= 1
        savefig = savefig_in;
    end

    % PROJECAO PATINO 1

    % modelo de predicao:
    %{
        e(tn) = Phi e(t0) + Gamma * dt
        Phi -> A
        Gamma -> B7
        dt -> u
    %}

    Phi   = [ 0.9713, 0.2192;
            -0.1707, 0.5857];

    Gamma = [2.4556; 
            0.9280];

    % modelo discretizado com T = 0.1s

    config.A = Phi;
    config.B = Gamma;

    % ganho de realimentacao K usando DLQR
    numel_x  = size(Phi, 2);
    numel_u  = size(Gamma,2);

    config.Q = diag(numel_x);
    config.R = diag(size(Gamma,2));

    % restricoes

    %{
        L dt >= c 
    %}

    L = toeplitz([1, -1], 1);

    c = [
        0.0;
        -0.04
    ];


    config.Sx = zeros(1, numel_x);
    config.bx = 0;

    config.Su = -L;
    config.bu = -c;

    config.xbar = [-0.5; -1.0];
    config.ubar = zeros(1, numel_u);

    config.N = 1;
    v1 = create_projection(config);
    config.N = 2;
    v2 = create_projection(config);
    config.N = 3;
    v3 = create_projection(config);

    f1 = figure(1);

    plot_proj(f1, v1, v2, v3, config.xbar);

    vnames = who;
    vout = {};
    for i = 1:numel(vnames)
        vi = vnames{i};
        vout.(vi) = eval(vi);
    end

    if savefig
        disp('salvando figura em pdf');
        name = sprintf("graf_proj_patino1.pdf", config.N);
        save_figure(f1, name, "../LATEX_tese/Cap4/fig/");
    end

end

function plot_proj(f, v1, v2, v3, xbar)

    clf;

    c1 = [1, 1, 1] * 0.7;
    c2 = [1, 1, 1] * 0.4;
    c3 = [1, 1, 1] * 0.2;

    plot(v3.D, 'color', c3);
    hold on;
    plot(v2.D, 'color', c2);
    plot(v1.D, 'color', c1);
    disp(xbar)
    plot(xbar(1),xbar(2), 'rx', 'markers', 12);
    hold off;

    % labels
    legend("N_p = 3", "N_p = 2", "N_p = 1");


    title('Buck-Boost Feasibility Region')
    xlabel('x_1: Voltage capacitor C');
    ylabel('x_2: Current inductor L');

    % ajustar tamanho da fonte
    ax = gca(f);
    set(ax,'fontsize', 15);
    zoom(f, 0.7);
    

end