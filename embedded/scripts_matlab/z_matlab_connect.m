% esp32_blink_control.m
clear;
clc;

% UUID definitions (must match ESP32)
SERVICE_UUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
CHAR_UUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

try
    % Scan for BLE devices
    fprintf('Scanning for ESP32_BLINK...\n');
    b = ble('ESP32_BLINK');
    
    % Connect to the service
    charac = characteristic(b, SERVICE_UUID, CHAR_UUID);
    
    fprintf('Connected to ESP32!\n');
    fprintf('Available commands:\n');
    fprintf('1. Type "START" to begin LED blinking\n');
    fprintf('2. Type "STOP" to stop LED blinking\n');
    fprintf('3. Type "INTERVAL" followed by milliseconds (e.g., "INTERVAL 1000")\n');
    fprintf('4. Type "EXIT" to quit\n\n');
    
    while true
        % Get command from user
        cmd = input('Enter command: ', 's');
        cmd = upper(cmd);  % Convert to uppercase
        
        % Process command
        if startsWith(cmd, 'INTERVAL')
            % Parse interval command
            parts = split(cmd);
            if length(parts) == 2
                interval = str2double(parts{2});
                if ~isnan(interval) && interval > 0
                    write(charac, unicode2native(['INTERVAL:' parts{2}], 'ASCII'));
                    fprintf('Set blink interval to %d ms\n', interval);
                else
                    fprintf('Invalid interval value!\n');
                end
            else
                fprintf('Invalid command format! Use "INTERVAL 1000"\n');
            end
        else
            switch cmd
                case 'START'
                    write(charac, unicode2native('START', 'ASCII'));
                    fprintf('Started LED blinking\n');

                case 'STOP'
                    write(charac, unicode2native('STOP', 'ASCII'));
                    fprintf('Stopped LED blinking\n');

                case 'EXIT'
                    fprintf('Disconnecting...\n');
                    clear b;
                    break;

                otherwise
                    fprintf('Invalid command!\n');
            end
        end
    end
    
catch ME
    fprintf('Error: %s\n', ME.message);
    if exist('b', 'var')
        clear b;
    end
end

fprintf('Program ended\n');