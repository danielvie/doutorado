

% k = [ 0.000416242448866209  0.00084516335645335  0.0095940645925792
%      -0.000417344537416973 -0.00084917861146434 -0.0095773668223236
%      -0.000835003627684464 -0.00040502724274651  0.0096153507389479
%       0.000839081838071992  0.00040617093509823 -0.0095993990256534
%       0.000833303406786859 -0.00081487214316475  0.0193015691040008];
% 
% ek = [0.6; 0.1; 0.1];
% 
% k_ = k';
% -k*ek
% 
% 
% msg = compute_matrix(k)

function s = compute_message(gain_k, times, modes)
    
    % gain_k
    str_gain_k_elements = arrayfun(@num2str, gain_k, 'UniformOutput', false);
    str_gain_k = strjoin(str_gain_k_elements, ',');
    [m,n] = size(gain_k);

    % times
    str_times_elements = arrayfun(@num2str, times, 'UniformOutput', false);
    str_times = strjoin(str_times_elements, ',');

    % modes
    str_modes_elements = arrayfun(@num2str, modes, 'UniformOutput', false);
    str_modes = strjoin(str_modes_elements, ',');

    s = sprintf("MESSAGE_DATA:%d;%d;%s;%s;%s;", m,n,str_gain_k,str_times,str_modes);
end




s = Simulation();
s.set_config(Enums.SimName.LAB_CIRCUIT);
% s.m_state_mode = Enums.StateMode.AUGMENTED;

mpc_config = s.get_mpc_config();
mpc_config.Nd = 15;
mpc_config.Np = 1; % Nd - Number of delays in the block (repeated control)

s.set_mpc_config(mpc_config);
s.set_traj_phase_with_alpha(0.3);
s.set_mpc();

s.m_config.mpc.x_target(3) = randn();

msg_data = s.get_msg_control_signal();
disp("msg_data:");
disp(msg_data);

b = BTBroker();
b.simulation = s;
b.msg(msg_data);
b.set_control_on(false);
% b.msg("TOGGLE_SET_B");
b.msg("CONTROL_OFF");
b.st();

% b.sa();
% pause(0.5);
% b.x();

% b.st();

% b.s(0.5);
% b.sa

% -k*ek =
% 
% -0.00129366826422298
%  0.00129306126582899
% -0.00042003017300946
%  0.00041587370621232
% -0.00234865174015572
