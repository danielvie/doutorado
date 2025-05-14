clear;

% connecting with BLE
SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
name = "ESP32 Signal Controller";

b = BTBroker(name, SERVICE_UUID, CHARACTERISTIC_UUID);

c =@(x) b.message(x);


s = Simulation();
s.set_config(Enums.SimName.LAB_CIRCUIT);

s.set_alpha_and_mpc_cached(0.5);


b.simulation = s;

% command for LAB alpha 0.5:
% time_us = [47, 47, 47, 47, 47, 47];
% mode = [4, 6, 2, 3, 1, 5];
% "SIGNAL:47, 47, 47, 47, 47, 47;4, 6, 2, 3, 1, 5";

time_us = s.get_time_us();
mode = s.get_mode();

command = Utils.signal_create( ...
     time_us, ...
     mode);

fprintf("command: %s\n", command)
b.message(command);


b.set_verbose(false);

b.message_cmd_cycles_nrun(25);
b.message_cmd_start();

disp(s)

%b.message("START");


% how to test
% 1. run this to connect with the device
% 2. change the setpoint of the device
%     >> b.s(0.7)

% broker commands:
%  s(self, alpha); % simulation.set_alpha_and_mpc_cached(alpha)
%  sa(self, alpha); % start()
%  so(self, alpha); % stop()
%  x(self); % stop()
%  set_verbose(self, value); % Set the verbosity level of the BTBroker. (default: false)
