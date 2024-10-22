% .. Create figure window
function guibt()
    fig = uifigure('Position', [100, 100, 550, 400]);
    add_btn_connect_bt(fig);
    add_btn_connect_serial(fig);
    add_led_buttons(fig);

    add_btn_signal(fig);
end

%% .. Add Buttons
function add_btn_connect_bt(fig)
    % Create the "Connect" button
    uibutton(fig, 'push', 'Text', 'Connect', ...
        'Position', [40, 300, 100, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_connect());

    % Create the "Disconnect" button
    uibutton(fig, 'push', 'Text', 'Disconnect', ...
        'Position', [160, 300, 100, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_disconnect());
end

function add_btn_connect_serial(fig)
    % Create the "Connect Serial" button
    uibutton(fig, 'push', 'Text', 'Connect Serial', ...
        'Position', [40, 100, 100, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_connect_serial());

    % Create the "Connect Serial" button
    uibutton(fig, 'push', 'Text', 'Disconnect Serial', ...
        'Position', [160, 100, 150, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_disconnect_serial());
end

function add_led_buttons(fig)
    % Create D_ buttons to send commands
    label = sprintf("0");
    uibutton(fig, 'push', 'Text', '0', ...
            'Position', [40, 230, 50, 50], ...
            'ButtonPushedFcn', @(btn, event) handle_send_command(label));

    % Create D_ buttons to send commands SERIAL
    uibutton(fig, 'push', 'Text', '0', ...
            'Position', [40, 30, 50, 50], ...
            'ButtonPushedFcn', @(btn, event) handle_send_command_serial(label));

    ii = 0;
    for i = 4:6
        ii = ii + 1;
        label = sprintf("D%d", i);
        uibutton(fig, 'push', 'Text', label, ...
            'Position', [40 + 60*(ii), 230, 50, 50], ...
            'ButtonPushedFcn', @(btn, event) handle_send_command(label));

        uibutton(fig, 'push', 'Text', label, ...
        'Position', [40 + 60*(ii), 30, 50, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_send_command_serial(label));
    end

end

function add_btn_signal(fig)
    % Create the "Connect Serial" button
    uibutton(fig, 'push', 'Text', 'Signal 1', ...
        'Position', [350, 300, 80, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_signal1());

    % Create the "Connect Serial" button
    uibutton(fig, 'push', 'Text', 'Signal 2', ...
        'Position', [450, 300, 80, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_signal2());
end

%% .. Handlers Bluetooth
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
        handle_send_command("0");
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

        % add terminator "\0" to command
        command_signal = sprintf("%s\0",command);

        write(o, command_signal, 'string');
        fprintf("command sent .. (bt): `%s`\n", command);
    else
        disp(command);
    end
end

%% .. Handlers Serial
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

        % add terminator "\0" to command
        command = sprintf("%s\0",command);

        oserial.send(command)
        fprintf("command sent (serial): `%s`\0", command);
    else
        disp(command);
    end
end

%% .. Handlers Signals
function handle_signal1()
    signal = construct_signal([1,2,3,4,5], [1,0,1,0,1]);
    fprintf("signal: `%s`\n", signal);
    % fprintf("sending modes: ""%s""\n", result);
end

function handle_signal2()
    signal = construct_signal([1,3,5,7,10], [1,0,1,0,1]);
    fprintf("signal: `%s`\n", signal);
end

%% .. Helpers
function result = construct_signal(time, mode)
    % convert arrays to strings
    time_str = sprintf('%d,', time);
    mode_str = sprintf('%d,', mode);

    % concatenate strings
    result = strcat(time_str, ";", mode_str, ";");

    % remove trailing commas
    result = strrep(result, ",;", ";");
end