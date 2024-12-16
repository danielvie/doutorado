function send_signal_bt(time, mode)
    
    signal = construct_signal(time, mode);
    command = sprintf("SIGNAL:%s", signal);
    % Check if 'o' exists in the workspace
    if evalin('base', 'exist(''b'', ''var'')')
        % Retrieve the bluetooth objects
        % b = evalin('base', 'b');
        charac = evalin('base', 'charac');

        fprintf("command sent .. (bt): `%s`\n", command);
        write(charac, unicode2native(command, 'ASCII'));
    else
        try
            [~, charac] = ble_connect();
            fprintf("command sent .. (bt): `%s`\n", command);

            write(charac, unicode2native(command, 'ASCII'));
        catch ME
            disp('command not sent!');
            fprintf('Error: %s\n', ME.message);
            disp(command);
        end
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