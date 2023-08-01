```matlab
    config:
        modes  % indice dos modos de operacao do sistema
        ur     % vetor de comandos de referencia
        Ac     % lista de matrizes A da dinamica
        Bc     % lista de matrizes B da dinamica
        Cc     % lista de matrizes C da dinamica
        Dc     % lista de matrizes D da dinamica
        tstep  % incremento de passo da simulacao
        xref   % estados de referencia para o controle
        tmin   % valor minimo de incremento de tempo
        Q      % matrix de peso para a otimizacao da trajetoria
        Tpmax  % Tp eh o periodo do ciclo, Tpmax eh o maximo valor permitido para o periodo da trajetoria ciclica calculada
        Ts     % tempo de sequencia de chaveamentos da trajetoria
        x0     % estados iniciais do sistema
        otmin  % valores para a funcao de otimizacao
                  %  x0: [0.2500 0.2500]
                  %  lb: [0.2500 0.2500]
                  %  ub: [1.5000 1.5000]
                  %   A: []
                  %   b: []
                  % Aeq: []
                  % beq: []
```

$\bar{x}^\infty$ : average reference value [number]
$T^\infty$ : switching times [array]
$\Omega^\infty$ : modes sequence [array]
