% Create a larger figure window
fig = uifigure('Position', [100, 100, 550, 400]);

% Create the "Connect" button
connectBtn = uibutton(fig, 'push', 'Text', 'Connect', ...
    'Position', [90, 300, 100, 50], ...
    'ButtonPushedFcn', @(btn, event) handle_connect());

% Create the "Disconnect" button
disconnectBtn = uibutton(fig, 'push', 'Text', 'Disconnect', ...
    'Position', [210, 300, 100, 50], ...
    'ButtonPushedFcn', @(btn, event) handle_disconnect());

% Create D_ buttons to send commands

uibutton(fig, 'push', 'Text', '0', ...
        'Position', [90, 200, 50, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_send_command('0'));

ii = 0;
for i = 4:6
    ii = ii + 1;
    label = sprintf("D%d", i);
    uibutton(fig, 'push', 'Text', label, ...
        'Position', [90 + 60*(ii), 200, 50, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_send_command(label));
end


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
        fprintf("command sent: `%s`\n", command);
    else
        disp(command);
    end
end
