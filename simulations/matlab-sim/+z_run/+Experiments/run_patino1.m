
res = play_patino1(false);
y_off = res.y_off;
y_on = res.y;

fprintf('Sum y_off: %f\n', sum(y_off(:)));
fprintf('Sum y_on:  %f\n', sum(y_on(:)));

if isequal(y_off, y_on)
    fprintf('The trajectories are EXACTLY the same.\n');
else
    fprintf('The trajectories are DIFFERENT.\n');
    fprintf('Norm of diff: %f\n', norm(y_off - y_on));
end

dtk_off = res.m_off; % Wait, res.m is modes. 
% In play_patino1.m, res = Utils.getAllVars() which should include everything.
if isfield(res, 'm_off')
    fprintf('Result has m_off\n');
end

% Check dtk from the log if available
% Since Utils.getAllVars() was used at line 42 of play_patino1.m, 
% it should have everything.
