function [b, charac] = ble_connect()
    % UUID definitions (must match ESP32)
    SERVICE_UUID = '4b887ab9-7677-4b0a-8371-113d46b91c1d';
    CHAR_UUID = '2ef72a2d-22cb-4ab8-8c03-affce243d888';

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