clear;

% connecting with BLE
SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
name = "ESP32 Signal Controller";

b = BTBroker(name, SERVICE_UUID, CHARACTERISTIC_UUID);

c =@(x) b.message(x);


s = Simulation();
s.set_config(Enums.SimName.LAB_CIRCUIT);

% for i = 0.1:0.01:0.9
%     fprintf("set i: %d\n", i);
%     s.set_alpha_and_mpc_cached(i);
% end

s.set_alpha_and_mpc_cached(0.5);
%s.set_mpc();

b.simulation = s;

% command for LAB alpha 0.5:
% time_us = [47, 47, 47, 47, 47, 47];
% mode = [4, 6, 2, 3, 1, 5];
% "SIGNAL:47, 47, 47, 47, 47, 47;4, 6, 2, 3, 1, 5";

time_us = s.get_time_us();
mode = s.get_mode();

command = Helpers.signal_create( ...
     time_us, ...
     mode);

fprintf("command: %s\n", command)
b.message(command);

b.message_cmd_cycles_nrun('10000');
b.message_cmd_start();

disp(s)

%b.message("START");


