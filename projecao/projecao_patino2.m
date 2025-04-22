function vout = projecao_patino2(savefig_in)

    %{
        N: nro de steps para a projecao
    %}
    
    savefig = false;
    
    if nargin >= 1
        savefig = savefig_in;
    end

    % PROJECAO PATINO 2

    % modelo de predicao:
    %{
        e(tn) = Phi e(t0) + Gamma * dt
        Phi -> A
        Gamma -> B7
        dt -> u
    %}

    Phi   = [ 
    0.9989   -0.0142    0.0873
    0.0142    0.9983    0.2390
    0.0005    0.0008    0.7580
            ];

    Gamma =  [
   -3.2002   -2.8219    0.0154    2.9377    3.0597
    2.9469    0.0195   -3.1915   -2.7616   -0.0501
   -0.0609    0.0904   -0.0572    0.1013   -0.1035
            ] * 1e4;

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

    % ?? dimensao da toeplitz, eh numel(c) x size(Gamma,2)?
    % L = toeplitz([1, -1, 0, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0, 0]);
    L = toeplitz([1, -1, 0, 0, 0, 0], [1, 0, 0, 0, 0]);

    c = [
   -0.7167
   -0.1567
   -0.7167
   -0.1567
   -0.7167
   -0.1567
    ] * 1e-4;


    config.Sx = zeros(1, numel_x);
    config.bx = 0;
    % config.Sx = eye(3)
    % config.bx = [30; 20; 20];

    config.Su = -L;
    config.bu = -c;

    config.xbar = [10.5636   21.1166    1.2081]';
    config.ubar = zeros(numel_u, 1);

    config.N  = 1;
    v1 = create_projection(config);
    config.N  = 2;
    v2 = create_projection(config);
    config.N  = 4;
    v4 = create_projection(config);

    % deslocando origem 
    v1.D = v1.D + config.xbar;
    v2.D = v2.D + config.xbar;
    v4.D = v4.D + config.xbar;

    % PP = Polyhedron('H',[[eye(3);-eye(3)] 1000*ones(6,1)]);
    % PP = intersect(v.D,PP);
    % clf, plot(PP2)

    f1 = figure(2);
    plotter.patino2.plot_projection(f1, v1, v2, v4, config.xbar, "N_p = 4", "N_p = 2", "N_p = 1")

    vnames = who;
    vout = {};
    for i = 1:numel(vnames)
        vi = vnames{i};
        vout.(vi) = eval(vi);
    end

    if savefig
        disp('salvando figura em pdf');

        addr = "../LATEX_tese/Cap4/fig/";

        % salvando figura view simetrico
        save_figure(f1, "graf_proj_patino2.pdf", addr);

        % salvando figura view por quadrante

        % ax = gca(f1);
        % view(ax, 0, 0);
        % save_figure(f1, name_13, addr);
        % view(ax, 0, 90);
        % save_figure(f1, name_12, addr);
        % view(ax, 90, 0);
        % save_figure(f1, name_23, addr);
    end

end