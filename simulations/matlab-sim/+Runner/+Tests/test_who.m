
function test_who()
    A = 1; B = 2;
    var_out = struct();
    varnames = who;
    fprintf('Vars: ');
    disp(varnames');
    for i = 1:numel(varnames)
        vi = varnames{i};
        if strcmp(vi, 'var_out'), continue; end
        var_out.(vi) = eval(vi);
    end
    disp('Result fields:');
    disp(fieldnames(var_out)');
end
