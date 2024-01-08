function vout = projecao_patino2(N_in, savefig_in)

    %{
        N: nro de steps para a projecao
    %}
    
    N = 1;
    savefig = false;
    
    if nargin >= 1
        N = N_in;
    end

    if nargin >= 2
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

    Phi   = [ 0.9994663      0.0019766     -0.1457479
            -0.0021148      0.9999105      0.0004491
            -0.0004916     -0.0002995      0.7483118
            ];

    Gamma =  [
                0.0096995  -2.4073879   2.4891683  -2.6175142   2.4800831   2.7168026  -2.3438879   2.3440669
                -2.5858563   2.4821412   0.0423572   2.3991777  -2.6053964   0           0           0
                -0.0801513  -0.0778152  -0.0746703   0.1687969   0.1013462  -0.0871122  -0.1889175   0.2000848
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

    L = toeplitz([1, -1, 0, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0, 0]);

    c = [
    -0.4283468
    -0.0440331
    -0.0457114
    -0.0269667
    -0.0276615
    -0.3903555
    -0.0515941
    -0.0676511
    -0.0241833
    ] * 1e-4;


    config.Sx = zeros(1, numel_x);
    config.bx = 0;
    % config.Sx = eye(3)
    % config.bx = [30; 20; 20];

    config.Su = -L;
    config.bu = -c;

    config.N  = N;


    config.xbar = [9.501818346682835; 19.837826908429342;  1.034416863494762];
    config.ubar = zeros(numel_u, 1);


    v = create_projection(config);

    % PP = Polyhedron('H',[[eye(3);-eye(3)] 1000*ones(6,1)]);
    % PP = intersect(v.D,PP);
    % clf, plot(PP2)

    f1 = figure(1);
    clf;
    plot(v.D);
    xlabel('x1');
    ylabel('x2');
    zlabel('x3');
    txt = sprintf("projecao patino 2 N:%d", config.N);
    title(txt)
    
    vnames = who;
    vout = {};
    for i = 1:numel(vnames)
        vi = vnames{i};
        vout.(vi) = eval(vi);
    end

    if savefig
        disp('salvando figura em pdf');

        addr = "../LATEX_tese/Cap4/fig/";
        name = sprintf("graf_proj_patino2_N_%d.pdf", config.N);

        % salvando figura view simetrico
        save_figure(f1, name, addr);

        % salvando figura view por quadrante
        name_13 = sprintf("graf_proj_patino2_N_%d_x1x3.pdf", config.N);
        name_12 = sprintf("graf_proj_patino2_N_%d_x1x2.pdf", config.N);
        name_23 = sprintf("graf_proj_patino2_N_%d_x2x3.pdf", config.N);

        ax = gca(f1);
        view(ax, 0, 0);
        save_figure(f1, name_13, addr);
        view(ax, 0, 90);
        save_figure(f1, name_12, addr);
        view(ax, 90, 0);
        save_figure(f1, name_23, addr);
    end

end