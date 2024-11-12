% .. Create figure window
function guibt_2()
    fig = uifigure('Position', [100, 100, 550, 400]);
    add_btn_connect_bt(fig);
    add_btn_log_on_off(fig);
    add_btn_test_blink(fig);
    add_btn_test_signal(fig);
    add_btn_test_digital_out(fig);
end

%% .. ui elements
function add_btn_connect_bt(fig)
    % Create the "Connect" button
    uibutton(fig, 'push', 'Text', 'Connect ..', ...
        'BackgroundColor', get_color('green'), ...
        'FontColor', 'white', ...
        'Position', [40, 330, 90, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_connect());

    % Create the "Disconnect" button
    uibutton(fig, 'push', 'Text', 'Disconnect ..', ...
        'BackgroundColor', get_color('red'), ...
        'FontColor', 'white', ...
        'Position', [140, 330, 90, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_disconnect());
end

function add_btn_log_on_off(fig)
    % Create the "Connect" button
    uibutton(fig, 'push', 'Text', 'Log ON', ...
        'Position', [40, 260, 90, 50], ...
        'ButtonPushedFcn', @(btn, event) send_command_bt("LOG_ON"));

    % Create the "Disconnect" button
    uibutton(fig, 'push', 'Text', 'Log OFF', ...
        'Position', [140, 260, 90, 50], ...
        'ButtonPushedFcn', @(btn, event) send_command_bt("LOG_OFF"));
end


function add_btn_test_blink(fig)

    hInputBox = uicontrol(fig, 'Style', 'edit', ...
        'Position', [350, 260, 80, 50], ...
        'String', '100', ...
        'FontSize', 12);

    uibutton(fig, 'push', 'Text', 'blink ON', ...
        'Position', [350, 330, 80, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_test_blink_on());

    uibutton(fig, 'push', 'Text', 'blink OFF', ...
        'Position', [450, 330, 80, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_test_blink_off());

    uibutton(fig, 'push', 'Text', 'blink SET ms', ...
        'Position', [450, 260, 80, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_test_blink_set(hInputBox));


    % intervals = [100, 200, 500, 1000, 2000];
    % for i = 1:numel(intervals)
    %     interval = intervals(i);
    %     command = sprintf("interval: %d", interval);
    %     uibutton(fig, 'push', 'Text', command, ...
    %         'Position', [40 + (i-1)*100, 110, 90, 50], ...
    %         'ButtonPushedFcn', @(btn, event) send_command_bt(upper(command)));
    % end
end

function add_btn_test_signal(fig)

    uicontrol(fig, 'Style', 'text', ...
                  'Position', [40, 132, 50, 40], ...
                  'String', 'time:', ...
                  'FontSize', 12, ...
                  'HorizontalAlignment', 'right');

    hInputTime = uicontrol(fig, 'Style', 'edit', ...
        'Position', [95, 140, 400, 40], ...
        'String', '[-1]', ...
        'FontSize', 11);

    uicontrol(fig, 'Style', 'text', ...
                  'Position', [40, 86, 50, 40], ...
                  'String', 'mode:', ...
                  'FontSize', 12, ...
                  'HorizontalAlignment', 'right');

    hInputMode = uicontrol(fig, 'Style', 'edit', ...
        'Position', [95, 95, 400, 40], ...
        'String', '[-1]', ...
        'FontSize', 11);

    hInputScale = uicontrol(fig, 'Style', 'edit', ...
        'Position', [40 + 160, 30, 75, 50], ...
        'String', '1', ...
        'FontSize', 12);

    % constructing signal 1
    time = [  0,   1000, 1333, 2333, 2666, 3666, 4000];
    mode = [  3,      7,    5,    7,    6,    7,    3];
    uibutton(fig, 'push', 'Text', 'signal 1', ...
        'Position', [40, 30, 75, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_signal_command(time, mode, hInputTime, hInputMode, hInputScale));

    % constructing signal 2
    time = [ 0, 1000, 2000, 3000, 4000, 5000, 6000];
    mode = [ 0,    1,    0,    1,    0,    1,    0];
    uibutton(fig, 'push', 'Text', 'signal 2', ...
        'Position', [40 + 80, 30, 75, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_signal_command(time, mode, hInputTime, hInputMode, hInputScale));

    % .. ON/OFF signals
    uibutton(fig, 'push', 'Text', 'SET', ...
        'Position', [290, 30, 60, 50], ...
        'ButtonPushedFcn', @(btn, event) handle_set_signal(hInputTime, hInputMode, hInputScale));

    uibutton(fig, 'push', 'Text', 'signal ON', ...
        'Position', [360, 30, 80, 50], ...
        'BackgroundColor', get_color('green'), ...
        'FontColor', 'white', ...
        'ButtonPushedFcn', @(btn, event) send_command_bt("SIGNAL_ON"));

    uibutton(fig, 'push', 'Text', 'signal OFF', ...
        'Position', [450, 30, 80, 50], ...
        'BackgroundColor', get_color('red'), ...
        'FontColor', 'white', ...
        'ButtonPushedFcn', @(btn, event) send_command_bt("SIGNAL_OFF"));
end

function add_btn_test_digital_out(fig)
    uibutton(fig, 'push', 'Text', '0', ...
        'Position', [40, 190, 90, 50], ...
        'ButtonPushedFcn', @(btn, event) send_command_bt("0"));

    uibutton(fig, 'push', 'Text', 'D4', ...
        'Position', [40 + 100, 190, 90, 50], ...
        'ButtonPushedFcn', @(btn, event) send_command_bt("D4"));

    uibutton(fig, 'push', 'Text', 'D5', ...
        'Position', [40 + 200, 190, 90, 50], ...
        'ButtonPushedFcn', @(btn, event) send_command_bt("D5"));

    uibutton(fig, 'push', 'Text', 'D6', ...
        'Position', [40 + 300, 190, 90, 50], ...
        'ButtonPushedFcn', @(btn, event) send_command_bt("D6"));
end

%% .. bluetooth handlers
% Callback function for "Connect" button
function handle_connect()
    ble_connect();    
end

function handle_signal_command(time, mode, hInputTime, hInputMode, hInputScale)
    % get value of input

    % timeText = get(hInputTime, 'String');
    % time = eval(timeText);

    % modeText = get(hInputMode, 'String');
    % mode = eval(modeText);

    scaleText = get(hInputScale, 'String');
    scale = str2double(scaleText);
    
    time_ = time*scale;
    set(hInputTime, 'String', mat2str(time_));

    mode_ = mode*scale;
    set(hInputMode, 'String', mat2str(mode_));
    
    % constructing signal
    % signal = construct_signal(time*scale, mode);
    % command = sprintf("SIGNAL:%s", signal);

    % % sending to ESP32
    % send_command_bt(command);
end

function handle_set_signal(hinput_time, hinput_mode, hinput_scale)
    time_str = get(hinput_time, 'String');
    time = eval(time_str);

    mode_str = get(hinput_mode, 'String');
    mode = eval(mode_str);

    scale_str = get(hinput_scale, 'String');
    scale = eval(scale_str);
    
    signal = construct_signal(time*scale, mode);
    command = sprintf("SIGNAL:%s", signal);

    send_command_bt(command);

end


% Callback function for "Disconnect" button
function handle_disconnect()
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

function handle_test_blink_on()
    send_command_bt('START')
end

function handle_test_blink_off()
    send_command_bt('STOP')
end

function handle_test_blink_set(hInputBox)
    inputText = get(hInputBox, 'String');
    interval = str2double(inputText);
    
    command = sprintf("interval: %d", interval);
    send_command_bt(upper(command));
end

%% .. serial handlers
% Callback function for "Connect" button
function handle_connect_serial()
    comPort = "COM11"; % Replace with your Arduino's COM port
    %comPort = "/dev/tty.usbserial-0001";
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

        % add terminator "\n" to command
        command_signal = sprintf("%s\n",command);

        oserial.send(command_signal)
        %write(oserial, command_signal, 'string');
        fprintf("command sent (serial): `%s`\n", command);

    else
        disp(command);
    end
end

%% .. helpers
function value = get_color(color)
    switch(lower(color))
        case "green"
            value = [0,0.4941,0];
        case "red"
            value = [0.53, 0.04, 0.04];
        otherwise
            disp("value not valid!");
    end
end

function result = construct_signal(time, mode)
    % convert arrays to strings
    time_str = sprintf('%d,', time);
    mode_str = sprintf('%d,', mode);

    % concatenate strings
    result = strcat(time_str, ";", mode_str, ";");

    % remove trailing commas
    result = strrep(result, ",;", ";");
end

% .. Callback function for sending commands via BT
function send_command_bt(command)
    % Check if 'o' exists in the workspace
    if evalin('base', 'exist(''b'', ''var'')')
        % Retrieve the bluetooth objects
        % b = evalin('base', 'b');
        charac = evalin('base', 'charac');

        write(charac, unicode2native(command, 'ASCII'));
        fprintf("command sent .. (bt): '%s'\n", command);
    else
        disp('command not sent!');
        disp(command);
    end
end
