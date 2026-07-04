% const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
% const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

% use `blelist` to list the bluetooth devices
clear;


% read control data
% config = engine.get_config_sim_patino_2();
% params = struct();
% params.E = 5;
% params.C(1) = 470e-6;
% params.C(2) = 470e-6;
% params.L = 100*1e-3;
% params.R = 22;
% 
% params.n = 3; % number of switing cells
% params.T = 0.28*1e-3; % period of cycle
% params.iMax = params.E/params.R;

% params.iLref = 0.1136; % << current setpoint
% params.alpha = params.iLref / params.iMax;

% params.alpha = 0.7;
% params.iLref = params.alpha * params.iMax;

% [Omega, dT, tt] = phase_shift.industrial_solution(params.alpha, params.n, params.T);
% [A,b] = phase_shift.modelSwitchedCapacitor(param.n,params.R,param.L,param.C,param.E);
% config.A = A;
% config.b = b;
% 
% dT_us = dT*1e6;







SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

name = "ESP32 Signal Controller";

device = ble(name);

%%
charList = characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID);

subscribe(charList);

%%
write(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID), uint8('SIGNAL:50,30;7,0'));

%%
write(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID), uint8('STOP'));

%%
write(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID), uint8('START'));

%%
% data = read(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID));

% Set up script running to allow callbacks to execute
charList.DataAvailableFcn = @(src, event) handleNewMessage(src, event);

while true
    %value = char(read(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID)));
    % message = waitForMessage(device, SERVICE_UUID, CHARACTERISTIC_UUID);
    % disp(message);

    pause(0.1); % Keep the script alive
end

function message = handleNewMessage(src, ~)
    % Read the new message
    message = char(read(src));
    disp(['Received message: ', message]);
    
    % Perform computation on the message
    computeMessage(message)
end

function computeMessage(message)
    % parsing message
    tokens = regexp(message, '(\w+):([\d.]+)', 'tokens');
    parsed_data = struct();
    for i = 1:length(tokens)
        key = tokens{i}{1};
        value = str2double(tokens{i}{2});
        parsed_data.(key) = value;
    end
    
    %  compute one cicle of control

    % compute dtk
    % [dtk, ~, ~] = mpc.mpc_dualmode_switching(ek,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,cfg.mpc.PhiNp,cfg.mpc.p);

    % Ts = config.Ts;
    % for j = 1:numel(dtk)
    %     Ts(j+1) = Ts(j+1) + dtk(j);
    % end

    % config.Ts = Ts;
    
    % convert to 

    %disp(['Performing computation: ', message]);
    %disp(['Message length: ', num2str(length(message))]);
    disp(parsed_data);
    disp(['a6 - a5: ', num2str(parsed_data.an6-parsed_data.an5)]);
end