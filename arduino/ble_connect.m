function [b, charac] = ble_connect()
    % UUID definitions (must match ESP32)
    SERVICE_UUID = '4b887ab9-7677-4b0a-8371-113d46b91c1d';
    CHAR_UUID = '2ef72a2d-22cb-4ab8-8c03-affce243d888';

    try
        [b, charac] = connect(SERVICE_UUID, CHAR_UUID);
    catch ME
        fprintf('Error: %s\n', ME.message);

        disp('try again ...');
        try
            disconnect();
            [b, charac] = connect(SERVICE_UUID, CHAR_UUID);
        catch ME
            if exist('b', 'var')
                clear b;
                clear charac;
            end
        end
    end
    % o = bluetooth("ESP32_BT", 1);

    % assignin('base', 'o', o);  % Register object 'o' in the base workspace
    % disp('Connected: Object o registered in workspace.');
end

function [b, charac] = connect(SERVICE_UUID, CHAR_UUID)
        % scan for BLE devices
        fprintf('Scanning for ESP32_BLINK...\n');
        b = ble('ESP32_BLINK');

        % connect to the service
        charac = characteristic(b, SERVICE_UUID, CHAR_UUID);

        % save values in `base`
        assignin('base', 'b', b);  % Register object 'o' in the base workspace
        assignin('base', 'charac', charac);  % Register object 'o' in the base workspace
        
        fprintf("Connected to ESP32!\n");
end

function disconnect()
    % Check if 'o' exists in the workspace and delete it
    disp('Disconnecting...');
    if evalin('base', 'exist(''b'', ''var'')')
        % handle_send_command_bt("0");
        evalin('base', 'clear b');  % Deregister object 'b' from the workspace
        disp('Object `b` cleared!');

        evalin('base', 'clear charac');  % Deregister object 'b' from the workspace
        disp('Object `charac` cleared!');
    else
        disp('Object o does not exist in workspace.');
    end
end