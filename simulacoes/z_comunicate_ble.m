% const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
% const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

% use `blelist` to list the bluetooth devices
clear;

SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

name = "ESP32 Signal Controller";

device = ble(name);

%%
charList = characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID);

subscribe(charList);

%%
write(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID), uint8('SIGNAL:50,30;7,0'));

%%
write(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID), uint8('STOP'));

%%
write(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID), uint8('START'));

%%
% data = read(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID));

% Set up script running to allow callbacks to execute
charList.DataAvailableFcn = @(src, event) handleNewMessage(src, event);

while true
    %value = char(read(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID)));
    % message = waitForMessage(device, SERVICE_UUID, CHARACTERISTIC_UUID);
    % disp(message);

    pause(0.1); % Keep the script alive
end

function message = handleNewMessage(src, ~)
    % Read the new message
    message = char(read(src));
    disp(['Received message: ', message]);
    
    % Perform computation on the message
    computeMessage(message)
end

function computeMessage(message)
    % parsing message
    tokens = regexp(message, '(\w+):([\d.]+)', 'tokens');
    parsed_data = struct();
    for i = 1:length(tokens)
        key = tokens{i}{1};
        value = str2double(tokens{i}{2});
        parsed_data.(key) = value;
    end

    disp(['Performing computation: ', message]);
    disp(['Message length: ', num2str(length(message))]);
end