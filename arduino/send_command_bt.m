function send_command_bt(command)
    % Check if 'o' exists in the workspace
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