function b = z_broker_simple()

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

    % connecting with BLE
    SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
    CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
    name = "ESP32 Signal Controller";
    
    b = BTBroker(name, SERVICE_UUID, CHARACTERISTIC_UUID);