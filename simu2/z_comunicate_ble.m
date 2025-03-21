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