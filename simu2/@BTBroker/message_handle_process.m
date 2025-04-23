function message_handle_process(self, msg)
    % parsing message
    tokens = regexp(msg, '(\w+):([\d.]+)', 'tokens');
    parsed_data = struct();
    for i = 1:length(tokens)
        key = tokens{i}{1};
        value = str2double(tokens{i}{2});
        parsed_data.(key) = value;
    end
    
    if self.verbose
        disp('Parsed data:');
        disp(parsed_data);
    end
    
     % v_c1 -> a5
     % v_c2 -> a6
     % v_i  -> a3

    v_c2 = parsed_data.an6;
    v_c1 = parsed_data.an5;
    i_l  = parsed_data.an3 / 22; % tensao / resistencia resistor
    state = [v_c1; v_c2; i_l;];
    
    if self.verbose
        disp('Received state:');
        disp(state);
    end
    % xtarget = [1.6667; 3.3391; 0.0583];

    time_us = self.simulation.signal_process(state);
    mode = self.simulation.get_mode();

    command = Helpers.signal_create(time_us, mode);
    
    if self.verbose
        disp('Sending command:');
        disp(command);
    end

    self.message(command);

end
