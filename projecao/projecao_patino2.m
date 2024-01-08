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

    config.xbar = [9.501818346682835; 19.837826908429342;  1.034416863494762];
    config.ubar = zeros(numel_u, 1);

    config.N  = 1;
    v1 = create_projection(config);
    config.N  = 2;
    v2 = create_projection(config);
    config.N  = 3;
    v3 = create_projection(config);
    config.N  = 4;
    v4 = create_projection(config);

    % PP = Polyhedron('H',[[eye(3);-eye(3)] 1000*ones(6,1)]);
    % PP = intersect(v.D,PP);
    % clf, plot(PP2)
    
    f1 = figure(1);
    plot_projection(f1, v1, v2, v3, config.xbar, "N_p = 3", "N_p = 2", "N_p = 1")

    f2 = figure(2);
    plot_projection(f2, v1, v2, v4, config.xbar, "N_p = 4", "N_p = 2", "N_p = 1")

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
        save_figure(f2, "graf_proj_patino2_2.pdf", addr);

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

function plot_projection(f, v1, v2, v3, xbar, varargin)

    clf;

    % colors
    % c1 = [1, 1, 1] * 0.7;
    % c2 = [1, 1, 1] * 0.4;
    % c3 = [1, 1, 1] * 0.2;
    c1 = [0.06, 0.32, 0.69];
    c2 = [0.69, 0.06, 0.32];
    c3 = [0.32, 0.69, 0.06];

    ax = gca(f);

    plot(v3.D, 'color', c3);
    hold on;
    plot(v2.D, 'color', c2);
    plot(v1.D, 'color', c1);
    disp(xbar)
    plot(xbar(1),xbar(2), 'rx', 'markers', 12);
    hold off;

    alpha(ax, 0.4);

    % labels
    legend(varargin{:});
    title('Multilevel Converter Factibility Region');
    xlabel('x_1: Voltage Capacitor C_1');
    ylabel('x_2: Voltage Capacitor C_2');
    zlabel('x_3: Current Inductor L');


    % ajustar tamanho da fonte
    set(ax,'fontsize', 17);
    % zoom(f, 0.7);
    
end