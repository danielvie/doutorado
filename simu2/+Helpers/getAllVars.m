function vout = getAllVars() 
    vout = struct();
    vnames = evalin('caller', 'who');
    for i = 1:numel(vnames)
        vi = vnames{i};
        vout.(vi) = evalin('caller', vi);
    end
end