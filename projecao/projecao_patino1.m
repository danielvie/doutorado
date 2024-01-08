function vout = projecao_patino1(N_in, savefig_in)

    N = 1;
    savefig = false;

    if nargin >= 1
        N = N_in
    end
    
    if nargin >= 2
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

    config.N = N;

    config.xbar = [-0.5; -1.0];
    config.ubar = zeros(1, numel_u);


    v = create_projection(config);

    f1 = figure(1);
    plot(v.D);
    txt = sprintf("projecao patino 1 N:%d", config.N);
    title(txt)

    vnames = who;
    vout = {};
    for i = 1:numel(vnames)
        vi = vnames{i};
        vout.(vi) = eval(vi);
    end

    if savefig
        disp('salvando figura em pdf');
        name = sprintf("graf_patino1_N_%d.pdf", config.N);
        save_figure(f1, name, "../LATEX_tese/Cap4/fig/");
    end

end