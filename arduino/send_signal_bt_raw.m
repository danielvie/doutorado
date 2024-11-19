function send_signal_bt_raw(command)
    
    if evalin('base', 'exist(''b'', ''var'')')
        % Retrieve the bluetooth objects
        % b = evalin('base', 'b');
        charac = evalin('base', 'charac');

        write(charac, unicode2native(command, 'ASCII'));
        fprintf("command sent .. (bt): `%s`\n", command);
    else
        disp('command not sent!');
        disp(command);
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