% Create a larger figure window
fig = uifigure('Position', [100, 100, 550, 400]);

%% CONNECT BLUETOOTH
% Create the "Connect" button
connectBtn = uibutton(fig, 'push', 'Text', 'Connect', ...
    'Position', [90, 300, 100, 50], ...
    'ButtonPushedFcn', @(btn, event) handle_connect());

% Create the "Disconnect" button
disconnectBtn = uibutton(fig, 'push', 'Text', 'Disconnect', ...
    'Position', [210, 300, 100, 50], ...
    'ButtonPushedFcn', @(btn, event) handle_disconnect());

%% CONNECT SERIAL
% Create the "Connect Serial" button
connectSerial = uibutton(fig, 'push', 'Text', 'Connect Serial', ...
    'Position', [90, 100, 100, 50], ...
    'ButtonPushedFcn', @(btn, event) handle_connect_serial());

% Create the "Connect Serial" button
disconnectSerial = uibutton(fig, 'push', 'Text', 'Disconnect Serial', ...
    'Position', [210, 100, 150, 50], ...
    'ButtonPushedFcn', @(btn, event) handle_disconnect_serial());

%% ADD BUTTONS
% Create D_ buttons to send commands
uibutton(fig, 'push', 'Text', '0', ...
        'Position', [90, 230, 50, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_send_command('0'));

% Create D_ buttons to send commands SERIAL
uibutton(fig, 'push', 'Text', '0', ...
        'Position', [90, 30, 50, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_send_command_serial('0'));

ii = 0;
for i = 4:6
    ii = ii + 1;
    label = sprintf("D%d", i);
    uibutton(fig, 'push', 'Text', label, ...
        'Position', [90 + 60*(ii), 230, 50, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_send_command(label));

    uibutton(fig, 'push', 'Text', label, ...
    'Position', [90 + 60*(ii), 30, 50, 50], ...
    'ButtonPushedFcn', @(btn, event) handle_send_command_serial(label));
end


%% botao hello
uibutton(fig, 'push', 'Text', 'hello', ...
        'Position', [400, 230, 50, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_send_command('hello to you'));


%% HANDLERS BLUETOOTH
% Callback function for "Connect" button
function handle_connect()
    o = bluetooth("ESP32_BT", 1);

    assignin('base', 'o', o);  % Register object 'o' in the base workspace
    disp('Connected: Object o registered in workspace.');
end


% Callback function for "Disconnect" button
function handle_disconnect()
    % Check if 'o' exists in the workspace and delete it
    if evalin('base', 'exist(''o'', ''var'')')
        handle_send_command('0');
        evalin('base', 'clear o');  % Deregister object 'o' from the workspace
        disp('Disconnected: Object o removed from workspace.');
    else
        disp('Object o does not exist in workspace.');
    end
end

% Callback function for sending commands via D_ buttons
function handle_send_command(command)
    % Check if 'o' exists in the workspace
    if evalin('base', 'exist(''o'', ''var'')')
        % Retrieve the object 'o' from the base workspace
        o = evalin('base', 'o');

        % Send the command to the object
        % o.send(command);  % Modify this method according to your object definition

        write(o, command, 'string');
        fprintf("command sent (bt): `%s`\n", command);
    else
        disp(command);
    end
end

%% HANDLERS SERIAL
% Callback function for "Connect" button
function handle_connect_serial()
    % comPort = "COM11"; % Replace with your Arduino's COM port
    comPort = "/dev/tty.usbserial-0001";
    baudRate = 115200;
    oserial = Com(comPort, baudRate);

    assignin('base', 'oserial', oserial);  % Register object 'o' in the base workspace
    disp('Connected: Object o registered in workspace.');
end

% Callback function for "Disconnect" button
function handle_disconnect_serial()
    % Check if 'o' exists in the workspace and delete it
    if evalin('base', 'exist(''oserial'', ''var'')')
        evalin('base', 'clear oserial');  % Deregister object 'o' from the workspace
        disp('Disconnected: Object o removed from workspace.');
    else
        disp('Object o does not exist in workspace.');
    end
end

% Callback function for sending commands via D_ buttons
function handle_send_command_serial(command)
    % Check if 'o' exists in the workspace
    if evalin('base', 'exist(''oserial'', ''var'')')
        % Retrieve the object 'o' from the base workspace
        oserial = evalin('base', 'oserial');

        oserial.send(command)
        fprintf("command sent (serial): `%s`\n", command);
    else
        disp(command);
    end
end
