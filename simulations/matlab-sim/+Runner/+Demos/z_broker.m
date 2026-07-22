clear;

% connecting with BLE
SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
name = "ESP32 Signal Controller";

b = BTBroker(name, SERVICE_UUID, CHARACTERISTIC_UUID);

s = Simulation();
s.set_config(Enums.SimName.LAB_CIRCUIT);

config_mpc = Options.Mpc();
config_mpc.Nd = 15;
config_mpc.Np = 25;
config_mpc.state_mode = Enums.StateMode.AUGMENTED;
s.set_mpc(config_mpc);

b.simulation = s;

b.s(0.5);

b.set_control_on(false);

b.set_cycles_nrun(config_mpc.Nd);
% b.msg_start();

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
