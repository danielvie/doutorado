function Xr = get_xr(self)
    % get_xr - calcula valores de `xr`
    % 
    % Prototype   : Xr = get_xr(config)
    % Description : propaga os estados da trajetoria de referencia calculando as matrizes de dinamica discretas usando  `c2dm`
    %               xr_1 = F_0*xr_0 + G_0;
    %               xr_2 = F_1*xr_1 + G_1;
    %               ...
    %               xr_N = F_{N-1}*xr_{N-1} + G_{N-1};
    %               
    %               [F_i, G_i] = c2dm(Ai, Bi, [], [], dti, 'zoh')
    %               Ai : matrix A da dinamica no modo de operacao `i`
    %               Bi : matrix B da dinamica no modo de operacao `i`
    %               dti: intervalo de tempo entre xr_i e xr_{i+ 1}
    % 
    % 
    % In          : config - estrutura de dados do caso a simular
    % 
    % Out         : Xr - estados da trajetoria de referencia em cada instante de chaveamento nominal
    % 
    % Pre. Cond   : nenhuma
    % 
    % Post. Cond. : nenhuma
    %
    % Notes       : nenuma
    % 
    % --------------------------------------------------------------------------------
    % 
    %           MATLAB Module
    % 
    % --------------------------------------------------------------------------------
    %
    % Author : Daniel Vieira {dvieira}
    % 
    % History
    % 2021-12-15: 1 - dvieira -  init
    
    config = self.config;

    A  = config.A;
    B  = config.b;
    Ts = config.Ts;

    M  = config.Omega;
    
    Xr = reshape(config.x0, [1, numel(config.x0)]);
    for i = 1:numel(M)
        mi  = M(i);
        Ai  = A{mi};
        Bi  = B{mi};
        dti = Ts(i+1) - Ts(i);

        [Fi, Gi] = c2dm(Ai,Bi,[],[],dti,'zoh');
        xi       = Fi*Xr(i,:)' + Gi;

        Xr = [Xr;xi'];
    end

end