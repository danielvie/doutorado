
%% calculo da trajetoria

% get custom options for the fmincon
opt = engine.get_otmin_opt(config);
opt.MaxFunctionEvaluations = 500*12;
opt.Display = 'iter';
opt.ConstraintTolerance = 1e-4;
% opt.PlotFcn = 'optimplotfvalconstr';

% open figure
% figure(5);
% clf();

[config, x, fval] = engine.otmin(config, opt);
