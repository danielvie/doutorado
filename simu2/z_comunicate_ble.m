clear;

% connecting with BLE
SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
name = "ESP32 Signal Controller";

b = BTBroker(name, SERVICE_UUID, CHARACTERISTIC_UUID);

s = Simulation();
s.set_config(Enums.SimName.LAB_CIRCUIT);

s.set_traj_phase_with_alpha(0.5);
s.set_mpc();

b.simulation = s;

% command for LAB alpha 0.5:
%command = "SIGNAL:47, 47, 47, 47, 47, 47;4, 6, 2, 3, 1, 5";


time_ms = [47, 47, 47, 47, 47, 47];
% % mode = [4, 6, 2, 3, 1, 5];
% mode = [7, 0, 7, 0, 7, 0];

% command = Helpers.signal_create( ...
%     time_ms, ...
%     mode);

b.message("SIGNAL:50,50,50,50,50,50;7,0,7,0,7,0");
% b.message("SIGNAL:500,500;7,0");
s.config.Ts = time_ms*1e-3;
b.message_cmd_cycles_nrun('10000000');
b.message("START");


c =@(x) b.message(x);
c('SIGNAL:75,19;1,4')
