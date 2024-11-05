function [b, charac] = ble_connect()
    % UUID definitions (must match ESP32)
    SERVICE_UUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
    CHAR_UUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

    try
        % scan for BLE devices
        fprintf('Scanning for ESP32_BLINK...\n');
        b = ble('ESP32_BLINK');

        % connect to the service
        charac = characteristic(b, SERVICE_UUID, CHAR_UUID);

        % save values in `base`
        assignin('base', 'b', b);  % Register object 'o' in the base workspace
        assignin('base', 'charac', charac);  % Register object 'o' in the base workspace
        
        fprintf("Connected to ESP32!\n");
    catch ME
        fprintf('Error: %s\n', ME.message);
        if exist('b', 'var')
            clear b;
        end
    end
    % o = bluetooth("ESP32_BT", 1);

    % assignin('base', 'o', o);  % Register object 'o' in the base workspace
    % disp('Connected: Object o registered in workspace.');
end