clear;

% connecting with BLE
SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
name = "ESP32 Signal Controller";

b = BTBroker(name, SERVICE_UUID, CHARACTERISTIC_UUID);

c =@(x) b.msg(x);

s = Simulation();
s.set_config(Enums.SimName.LAB_CIRCUIT);
s.m_state_mode = Enums.StateMode.AUGMENTED;

% s.set_alpha_and_mpc_cached(0.5);

mpc_config = s.get_mpc_config();
mpc_config.Nd = 15;
mpc_config.Np = 25;
s.set_mpc_config(mpc_config);
s.set_mpc();

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

b.msg(command);


b.set_control_on(false);
% b.set_verbose(false);


b.set_cycles_nrun(mpc_config.Nd);
b.s(0.5);
b.msg_start();

disp(s)

% b.msg("START");


% how to test
% 1. run this to connect with the device
% 2. change the setpoint of the device
%     >> b.s(0.7)

% broker commands:
%
% b.simulation.set_alpha_and_mpc_cached(alpha) 
% alias: b.s(alpha); 
%
% b.start()
% alias: b.sa(); 
%
% b.stop()
% alias: b.so(); 
% alias: b.x(); 
%
% Set the control ON/OFF (true/false)
% b.set_control_on(value);
%
% Set the verbosity level of the BTBroker. (default: false)
% b.set_verbose(value); 
% 
% b.set_cycles_nrun(value);
% 
% Get status of the variables
% b.msg("STATUS");
% alias: b.st();