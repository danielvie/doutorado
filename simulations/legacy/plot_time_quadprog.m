
function plot_time_quadprog()

r = patino2_phase_mpc();
close all;
% r = evalin('caller', 'r');

l1 = r.data.log1;
% l2 = r.data.log2;

tam = numel(l1);
% imax = 1;
tmax = -1;
tt = zeros(tam, 1);
V = cell(tam, 1);

for i = 1:tam
    
    % if i < 3
    %     continue;
    % end
    
    li = l1{i};
    
    tt(i) = li.time_quadprog;
    V{i} = li;
    
    if li.time_quadprog > tmax
        tmax = li.time_quadprog;
        vmax = li;
    end
    
end

v = vmax;
t = tmax;

i = cellfun(@(x) x.i, V);
time = tt*1000;
tab = table(i, time);


assignin('caller', 'v', v);
assignin('caller', 'V', V);
assignin('caller', 'tmax', t);
assignin('caller', "tt", tt);
assignin('caller', "tab", tab);


plot(tt*1000, '+-');
grid on;
xlabel("iteracao")
ylabel("time (ms)")

end
